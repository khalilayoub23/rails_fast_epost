require "bigdecimal"
require "securerandom"

class TasksController < ApplicationController
  include Respondable

  TaskPaymentError = Class.new(StandardError)

  before_action :set_customer, only: %i[index new create]
  before_action :set_task, only: %i[show edit update destroy update_status update_delivery]
  before_action :load_form_collections, only: %i[new create payment_cancel]

  def index
    @tasks = if @customer
      @customer.tasks
    else
      Task.all
    end
    respond_with_index(@tasks)
  end

  def show
    respond_with_show(@task)
  end

  def new
    @task = (@customer ? @customer.tasks : Task).new
    @payment_details = default_payment_details
  end

  def create
    scope = @customer ? @customer.tasks : Task
    @task = scope.new(task_params)
    @payment_details = default_payment_details.merge(payment_form_params.to_h)

    unless @task.valid?
      flash.now[:alert] = t("tasks.form_error", default: "Please correct the highlighted errors.")
      render :new, status: :unprocessable_entity and return
    end

    payment = initiate_task_checkout!(@task, @payment_details)

    if payment.payment_url.present?
      redirect_to payment.payment_url, allow_other_host: true, status: :see_other
    else
      task = finalize_task_from_payment(payment)
      redirect_to task_path(task), notice: t("tasks.created_after_payment", default: "Task created after successful payment."), status: :see_other
    end
  rescue TaskPaymentError => e
    Rails.logger.warn("[Tasks#create] Payment error: #{e.message}")
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  rescue => e
    Rails.logger.error("[Tasks#create] Unexpected error: #{e.message}")
    flash.now[:alert] = t("tasks.payment_unexpected_error", default: "Unable to start checkout. Please try again.")
    render :new, status: :internal_server_error
  end

  def edit
    @senders = Sender.order(:name)
    @messengers = Messenger.order(:name)
    @carriers = Carrier.order(:name)
  end

  def update
    respond_with_update(@task, @task.customer, notice: "Task updated.") do
      render turbo_stream: [
        turbo_stream.replace(@task, partial: "tasks/task_card", locals: { task: @task }),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: t("tasks.updated_successfully") })
      ]
      task_params
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
    @task = Task.new(task_form)
    @payment_details = default_payment_details.merge(payment_form)
    @task.customer ||= Customer.find_by(id: task_form["customer_id"]) if task_form["customer_id"].present?
    @customer = @task.customer if @task.customer
    flash.now[:alert] = t("tasks.payment_canceled", default: "Payment canceled. Review the details and try again.")
    render :new, status: :unprocessable_entity
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def load_form_collections
    @senders = Sender.order(:name)
    @messengers = Messenger.available.order(:name)
    @carriers = Carrier.order(:name)
  end

  def task_params
    params.require(:task).permit(
      :customer_id, :carrier_id, :sender_id, :messenger_id, :lawyer_id,
      :package_type, :start, :target, :failure_code, :delivery_time, :status, :filled_form_url,
      :pickup_address, :pickup_contact_phone, :pickup_notes, :requested_pickup_time
    )
  end

  def payment_form_params
    params.fetch(:payment, {}).permit(:amount, :currency, :service_type, :description)
  end

  def default_payment_details
    {
      "amount" => nil,
      "currency" => "USD",
      "service_type" => "standard_delivery",
      "description" => nil
    }
  end

  def initiate_task_checkout!(task, payment_details)
    amount_cents = parse_amount_cents(payment_details["amount"])
    raise TaskPaymentError, t("tasks.payment_amount_invalid", default: "Payment amount must be greater than zero.") if amount_cents <= 0

    currency = payment_details["currency"].presence || "USD"
    cancel_token = SecureRandom.hex(12)

    metadata = {
      "task_snapshot" => serialize_task_snapshot(task),
      "task_form" => task_params.to_h,
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
  end

  def parse_amount_cents(amount_value)
    amount = BigDecimal(amount_value.to_s)
    (amount * 100).to_i
  rescue ArgumentError, TypeError
    0
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
