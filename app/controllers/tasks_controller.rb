require "bigdecimal"
require "securerandom"

class TasksController < ApplicationController
  include Respondable

  TaskPaymentError = Class.new(StandardError)

  before_action :set_customer, only: %i[index new create]
  before_action :set_task, only: %i[show edit update destroy update_status update_delivery publish]
  before_action :authorize_task!, only: %i[show edit update destroy update_status update_delivery publish]
  before_action :load_form_collections, only: %i[new create payment_cancel]
  before_action :require_task_creator!, only: %i[new create payment_cancel publish]

  def index
    base_scope = policy_scope(Task)
    base_scope = base_scope.where(customer_id: @customer.id) if @customer

    # Handle search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      base_scope = base_scope.where(
        "barcode ILIKE ? OR package_type ILIKE ? OR start ILIKE ? OR target ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    @priority_filter = params[:priority].presence
    if @priority_filter.present? && Task.priorities.key?(@priority_filter)
      base_scope = base_scope.where(priority: @priority_filter)
    else
      @priority_filter = nil
    end

    @tasks = apply_visibility_filter(base_scope)
    respond_with_index(@tasks)
  end

  def show
    @payment_details ||= default_payment_details
    @checkout_payment = Payment.where("metadata ->> 'task_id' = ?", @task.id.to_s)
      .where(provider: "stripe", gateway_status: %w[pending created])
      .order(created_at: :desc)
      .first
    respond_with_show(@task)
  end


  def publish
    unless current_user&.manager? || current_user&.support_agent? || @task.created_by_id == current_user&.id
      message = t("messages.unauthorized", default: "You are not authorized to perform this action.")
      redirect_to task_path(@task), alert: message and return
    end

    if @task.published?
      redirect_to task_path(@task), notice: t("tasks.already_published", default: "Task already published."), status: :see_other and return
    end

    @payment_details = default_payment_details.merge(payment_form_params.to_h)
    payment = initiate_task_checkout!(@task, @payment_details)

    if (Rails.env.development? || Rails.env.test?) && ENV.fetch("STRIPE_SIMULATE", "false") == "true"
      payment.update!(gateway_status: "succeeded")
      task = finalize_task_from_payment(payment)
      redirect_to task_path(task), notice: t("tasks.published_after_payment", default: "Payment confirmed. Task is now published."), status: :see_other and return
    end

    if payment.payment_url.present?
      redirect_to payment.payment_url, allow_other_host: true, status: :see_other
    elsif payment.gateway_status_succeeded?
      task = finalize_task_from_payment(payment)
      redirect_to task_path(task), notice: t("tasks.published_after_payment", default: "Payment confirmed. Task is now published."), status: :see_other
    else
      raise TaskPaymentError, t("tasks.payment_checkout_missing", default: "Unable to start Stripe checkout. Please contact an administrator.")
    end
  rescue TaskPaymentError => e
    Rails.logger.warn("[Tasks#publish] Payment error: #{e.message}")
    flash.now[:alert] = e.message
    render :show, status: :unprocessable_entity
  rescue => e
    Rails.logger.error("[Tasks#publish] Unexpected error: #{e.message}")
    flash.now[:alert] = t("tasks.payment_unexpected_error", default: "Unable to start checkout. Please try again.")
    render :show, status: :internal_server_error
  end
  def new
    @task = (@customer ? @customer.tasks : Task).new
    authorize @task
    load_poa_templates
  end

  def create
    if current_user&.manager? && payment_form_params[:amount].present?
      scope = @customer ? @customer.tasks : Task
      task = scope.new(task_params)
      authorize task
      assign_default_carrier(task)
      assign_lawyer_from_creator(task)

      payment_details = default_payment_details(task).merge(payment_form_params.to_h)
      amount_cents = parse_amount_cents(payment_details["amount"])
      raise TaskPaymentError, t("tasks.payment_amount_invalid", default: "Payment amount must be greater than zero.") if amount_cents <= 0

      cancel_token = SecureRandom.hex(12)
      task_snapshot = serialize_task_snapshot(task)
      metadata = {
        "task_snapshot" => task_snapshot,
        "task_form" => task_snapshot,
        "payment_form" => payment_details,
        "task_cancel_token" => cancel_token,
        "success_url" => task_payment_success_template_url,
        "cancel_url" => task_payment_cancel_url(token: cancel_token),
        "payment_service_type" => payment_details["service_type"],
        "payment_description" => payment_details["description"]
      }.compact

      payment = Gateways::StripeGateway.create_payment!(
        amount_cents: amount_cents,
        currency: payment_details["currency"].presence || "USD",
        task: nil,
        payable: task.customer,
        metadata: metadata
      )

      redirect_to payment.payment_url, allow_other_host: true, status: :see_other
      return
    end

    scope = @customer ? @customer.tasks : Task
    @task = scope.new(task_params)
    authorize @task
    assign_default_carrier(@task)
    assign_lawyer_from_creator(@task)
    @task.created_by = current_user
    # Unpaid tasks should remain postponed until payment completes.
    @task.status = :postponed unless @task.published?
    log_task_creation_attempt(@task)

    if @task.save
      add_task_to_cart_if_applicable(@task)
      @payment_details = default_payment_details
      @task = (@customer ? @customer.tasks : Task).new
      @task.customer = @customer if @customer
      authorize @task
      notice_message = t("tasks.created_notice", default: "Task created successfully.")

      respond_to do |format|
        redirect_path = @customer ? customer_tasks_path(@customer) : tasks_path

        format.turbo_stream do
          redirect_to redirect_path, notice: notice_message, status: :see_other
        end

        format.html do
          redirect_to redirect_path, notice: notice_message, status: :see_other
        end
      end
    else
      log_task_creation_failure(@task)
      flash.now[:alert] = t("tasks.form_error", default: "Please correct the highlighted errors.")
      load_poa_templates
      render :new, status: :unprocessable_entity
    end
  rescue TaskPaymentError => e
    Rails.logger.warn("[Tasks#create] Payment error: #{e.message}")
    flash.now[:alert] = e.message
    @task = (@customer ? @customer.tasks : Task).new(task_params)
    assign_default_carrier(@task)
    render :new, status: :unprocessable_entity
  rescue => e
    Rails.logger.error("[Tasks#create] Unexpected error: #{e.message}")
    flash.now[:alert] = t("tasks.general_creation_error", default: "Unable to save the task. Please try again.")
    @task = (@customer ? @customer.tasks : Task).new(task_params)
    assign_default_carrier(@task)
    load_poa_templates
    render :new, status: :internal_server_error
  end

  def edit
    @senders = Sender.order(:name)
    @messengers = Messenger.order(:name)
    @carriers = Carrier.order(:name)
    load_poa_templates
  end

  def update
    load_poa_templates
    respond_with_update(@task, @task.customer, notice: "Task updated.", attributes: task_params) do
      render turbo_stream: [
        turbo_stream.replace(@task, partial: "tasks/task_card", locals: { task: @task }),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: t("tasks.updated_successfully") })
      ]
    end
  end

  def destroy
    redirect_path = @task.customer ? customer_tasks_path(@task.customer) : tasks_path
    respond_with_destroy(@task, redirect_path, notice: "Task deleted.") do
      render turbo_stream: [
        turbo_stream.remove(@task),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: t("tasks.deleted_successfully") })
      ]
    end
  end

  def update_status
    if @task.update(status: params[:status])
      respond_to do |format|
        format.html { redirect_to @task, notice: "Task status updated." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@task, partial: "tasks/task_card", locals: { task: @task }),
            turbo_stream.append("flash-messages", partial: "shared/flash_message",
                               locals: { type: :success, message: t("tasks.status_updated") })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def update_delivery
    if @task.update(delivery_time: params[:delivery_time], failure_code: params[:failure_code])
      redirect_to @task, notice: "Task delivery updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def payment_success
    session_id = params[:session_id].to_s
    if session_id.blank?
      redirect_to new_task_path, alert: t("tasks.payment_missing_session", default: "Missing payment session information."), status: :see_other and return
    end

    payment = Payment.find_by(checkout_session_id: session_id)
    unless payment
      redirect_to new_task_path, alert: t("tasks.payment_not_found", default: "Payment session not found."), status: :see_other and return
    end

    begin
      if payment.gateway_status_pending? || payment.gateway_status_created?
        Gateways::StripeGateway.sync!(payment: payment)
      end
    rescue => e
      Rails.logger.warn("[Tasks#payment_success] Sync error: #{e.message}")
    end

    if payment.gateway_status_succeeded?
      task = finalize_task_from_payment(payment)
      redirect_to task_path(task), notice: t("tasks.payment_success_notice", default: "Payment confirmed and task saved."), status: :see_other
    else
      token = payment.metadata.to_h["task_cancel_token"]
      redirect_to task_payment_cancel_path(token: token), alert: t("tasks.payment_pending", default: "Payment is not completed yet."), status: :see_other
    end
  end

  def payment_cancel
    token = params[:token].to_s
    payment = Payment.where("metadata ->> 'task_cancel_token' = ?", token).first

    unless payment
      redirect_to new_task_path, alert: t("tasks.payment_cancel_unknown", default: "Payment session not found. Please start again."), status: :see_other and return
    end

    task_form = payment.metadata.fetch("task_form", {})
    payment_form = payment.metadata.fetch("payment_form", {})
    @task = payment.task || Task.find_by(id: payment.metadata["task_id"])

    if @task.present?
      @payment_details = default_payment_details.merge(payment_form)
      flash.now[:alert] = t("tasks.payment_canceled", default: "Payment canceled. Review the details and try again.")
      render :show, status: :unprocessable_entity
    else
      @task = Task.new(task_form)
      @task.customer ||= Customer.find_by(id: task_form["customer_id"]) if task_form["customer_id"].present?
      @payment_details = default_payment_details.merge(payment_form)
      flash.now[:alert] = t("tasks.payment_canceled", default: "Payment canceled. Review the details and try again.")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def add_task_to_cart_if_applicable(task)
    return unless current_user.present?
    return if task.published?

    return unless current_user.admin? || current_user.support_agent? || current_user.manager? || current_user.sender_role? || current_user.lawyer? || current_user.ecommerce_seller?

    Cart.for(current_user).add_task!(task)
  rescue => e
    Rails.logger.warn("[Tasks#create] Unable to add task to cart: #{e.message}")
    nil
  end

  def set_customer
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
  end

  def set_task
    @task = policy_scope(Task).find(params[:id])
  end

  def authorize_task!
    authorize @task
  end

  def load_form_collections
    @senders = Sender.order(:name)
    @messengers = Messenger.available.order(:name)
    @carriers = Carrier.order(:name)
  end

  def task_params
    permitted = params.require(:task).permit(
      :customer_id, :carrier_id, :sender_id, :messenger_id, :lawyer_id,
      :package_type, :task_type, :start, :target, :failure_code, :delivery_time, :status, :priority, :filled_form_url,
      :id_number,
      :collection_amount, :collection_currency,
      :poa_document_template_id, :poa_enabled,
      :archive_item_type, :archive_quantity, :archive_duration_days, :archive_from_date, :archive_to_date,
      :pickup_address, :pickup_contact_phone, :pickup_notes, :requested_pickup_time,
      :case_file_number, :delivery_medium, :power_of_attorney,
      legal_files: []
    )

    permitted.delete(:carrier_id) if current_user&.sender_role?
    unless current_user&.carrier?
      permitted.delete(:status)
      permitted.delete(:failure_code)
    end
    unless current_user&.admin? || current_user&.support_agent?
      permitted.delete(:messenger_id)
    end
    permitted
  end

  def load_poa_templates
    @poa_templates = DocumentTemplate.active_templates
                                    .where(category: "Power of Attorney")
                                    .order(:name)
  end

  def apply_visibility_filter(scope)
    return scope unless current_user&.sender_role?

    published_scope = scope.where(published: true)
    published_scope.or(scope.where(created_by_id: current_user.id))
  end

  def assign_default_carrier(task)
    return if task.carrier_id.present?

    task.carrier = Carrier.default_system_carrier
  end

  def assign_lawyer_from_creator(task)
    return unless current_user&.lawyer?
    return if task.lawyer_id.present?

    task.lawyer_id = current_user.ensure_lawyer_profile!&.id
  end

  def log_task_creation_attempt(task)
    role = current_user&.role || "n/a"
    user_info = "user_id=#{current_user&.id || 'guest'} role=#{role}"
    params_info = task_params.slice(:customer_id, :sender_id, :messenger_id, :carrier_id).to_h
    carrier_name = task.carrier&.name || "none"
    Rails.logger.info("\e[36m[TaskCreation]\e[0m Attempt by \e[35m#{user_info}\e[0m params=#{params_info} status=#{task.status} carrier=#{carrier_name}")
  end

  def log_task_creation_failure(task)
    Rails.logger.error("\e[31m[TaskCreation] validation failed: #{task.errors.full_messages.join(' | ')}\e[0m")
    Rails.logger.error("\e[33m[TaskCreation] incoming task params=#{task_params.to_h}\e[0m")
  end

  def payment_form_params
    params.fetch(:payment, {}).permit(:amount, :currency, :service_type, :description)
  end

  def default_payment_details(task = @task)
    amount = task_checkout_amount(task)

    {
      "amount" => amount || "100.00",
      "currency" => "ILS",
      "service_type" => "standard_delivery",
      "description" => nil
    }
  end

  def initiate_task_checkout!(task, payment_details)
    amount_cents = parse_amount_cents(payment_details["amount"])
    raise TaskPaymentError, t("tasks.payment_amount_invalid", default: "Payment amount must be greater than zero.") if amount_cents <= 0

    currency = payment_details["currency"].presence || "ILS"
    cancel_token = SecureRandom.hex(12)

    task_snapshot = serialize_task_snapshot(task)
    metadata = {
      "task_id" => task.id,
      "task_snapshot" => task_snapshot,
      "task_form" => task_snapshot,
      "payment_form" => payment_details,
      "task_cancel_token" => cancel_token,
      "success_url" => task_payment_success_template_url,
      "cancel_url" => task_payment_cancel_url(token: cancel_token),
      "payment_service_type" => payment_details["service_type"],
      "payment_description" => payment_details["description"],
      "task_customer_id" => task.customer_id
    }.compact

    Gateways::StripeGateway.create_payment!(
      amount_cents: amount_cents,
      currency: currency,
      task: nil,
      payable: task.customer,
      metadata: metadata
    )
  rescue Stripe::AuthenticationError => e
    Rails.logger.warn("[Tasks#publish] Stripe authentication error: #{e.message}")
    raise TaskPaymentError, t("tasks.payment_gateway_auth_error", default: "Payment provider credentials are invalid. Please contact an administrator.")
  end

  def require_task_creator!
    return if current_user&.manager? || current_user&.sender_role? || current_user&.lawyer? || current_user&.ecommerce_seller?

    message = t("messages.unauthorized", default: "You are not authorized to perform this action.")
    redirect_to root_path, alert: message
  end

  def parse_amount_cents(amount_value)
    amount = BigDecimal(amount_value.to_s)
    (amount * 100).to_i
  rescue ArgumentError, TypeError
    0
  end

  def task_checkout_amount(task)
    return nil unless task

    cost = CostCalculator.new(task).total_cost
    return nil unless cost.present? && cost.positive?

    format("%.2f", cost)
  rescue => e
    Rails.logger.warn("[Tasks] Failed to compute checkout amount for task #{task.id}: #{e.message}")
    nil
  end

  def serialize_task_snapshot(task)
    snapshot = task.snapshot_for_payment
    %w[delivery_time requested_pickup_time].each do |field|
      next unless snapshot[field].present?
      snapshot[field] = snapshot[field].iso8601 if snapshot[field].respond_to?(:iso8601)
    end
    snapshot
  end

  def task_payment_success_template_url
    "#{task_payment_success_url}?session_id={CHECKOUT_SESSION_ID}"
  rescue
    "#{fallback_app_base_url}/tasks/payment/success?session_id={CHECKOUT_SESSION_ID}"
  end

  def fallback_app_base_url
    ENV["APP_BASE_URL"].presence || "http://localhost:3000"
  end

  def finalize_task_from_payment(payment)
    TaskPaymentMaterializer.new(payment: payment).call
  end
end
