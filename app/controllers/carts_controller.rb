require "bigdecimal"
require "securerandom"

class CartsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_cart_owner!
  before_action :set_cart

  def show
    cleanup_published_items
    @items = @cart.cart_items
                  .joins(:task)
                  .where(tasks: { published: false })
                  .includes(task: %i[customer carrier])
  end

  def add_item
    task = Task.find(params[:task_id])
    authorize_cart_task!(task)

    if task.published?
      redirect_to task_path(task), alert: t("cart.task_already_paid", default: "This task is already paid/published."), status: :see_other and return
    end

    @cart.add_task!(task)
    redirect_back fallback_location: cart_path, notice: t("cart.added", default: "Added to cart."), status: :see_other
  end

  def remove_item
    item = @cart.cart_items.find(params[:id])
    @cart.remove_task!(item.task)
    redirect_back fallback_location: cart_path, notice: t("cart.removed", default: "Removed from cart."), status: :see_other
  end

  def checkout
    requested_task_ids = Array(params[:task_ids]).map(&:to_i).uniq
    requested_task_ids = @cart.tasks.pluck(:id) if requested_task_ids.empty?

    if requested_task_ids.empty?
      redirect_to cart_path, alert: t("cart.select_tasks", default: "Select at least one task to pay."), status: :see_other and return
    end

    tasks = @cart.tasks.where(id: requested_task_ids)

    if tasks.size != requested_task_ids.size
      redirect_to cart_path, alert: t("cart.invalid_selection", default: "Some selected tasks are no longer available in your cart."), status: :see_other and return
    end

    tasks.each { |t| authorize_cart_task!(t) }

    if tasks.any?(&:published?)
      redirect_to cart_path, alert: t("cart.contains_paid", default: "Cart contains tasks that are already paid/published."), status: :see_other and return
    end

    currency = params[:currency].to_s.presence || "ILS"

    per_task_amounts = extract_amounts_param
    line_items = []
    line_details = []
    total_cents = 0

    tasks.each do |task|
      amount_cents = amount_cents_for_task(task, per_task_amounts)
      raise ArgumentError, "Invalid amount" if amount_cents <= 0

      total_cents += amount_cents
      line_items << {
        price_data: {
          currency: currency.downcase,
          product_data: { name: task.title },
          unit_amount: amount_cents
        },
        quantity: 1
      }
      line_details << { "task_id" => task.id, "amount_cents" => amount_cents }
    end

    cancel_token = SecureRandom.hex(12)

    metadata = {
      "task_ids" => tasks.map(&:id),
      "line_items" => line_details,
      "stripe_line_items" => line_items,
      "cart_owner_id" => current_user.id,
      "success_url" => cart_success_template_url,
      "cancel_url" => cart_cancel_url_for(cancel_token),
      "cart_cancel_token" => cancel_token
    }

    payment = Gateways::StripeGateway.create_payment!(
      amount_cents: total_cents,
      currency: currency,
      task: nil,
      payable: current_user,
      metadata: metadata,
      payment_type: :lump_sum,
      category: :service_fee
    )

    payment.tasks << tasks
    payment.update!(task: tasks.first) if payment.task_id.blank? && tasks.first

    redirect_to payment.payment_url, allow_other_host: true, status: :see_other
  rescue ArgumentError
    redirect_to cart_path, alert: t("cart.invalid_amount", default: "Please enter a valid amount for each task."), status: :see_other
  end

  def success
    session_id = params[:session_id].to_s
    if session_id.blank?
      redirect_to cart_path, alert: t("cart.payment_missing_session", default: "Missing payment session information."), status: :see_other and return
    end

    payment = Payment.find_by(checkout_session_id: session_id)
    unless payment
      redirect_to cart_path, alert: t("cart.payment_not_found", default: "Payment session not found."), status: :see_other and return
    end

    unless payment.payable_type == "User" && payment.payable_id == current_user.id
      redirect_to cart_path, alert: t("cart.unauthorized", default: "You are not authorized to view this payment."), status: :see_other and return
    end

    begin
      Gateways::StripeGateway.sync!(payment: payment) if payment.gateway_status_pending? || payment.gateway_status_created?
    rescue => e
      Rails.logger.warn("[Cart#success] Sync error: #{e.message}")
    end

    if payment.gateway_status_succeeded?
      tasks = CartPaymentMaterializer.new(payment: payment).call
      @cart.cart_items.where(task_id: tasks.map(&:id)).destroy_all
      redirect_to cart_path, notice: t("cart.payment_success", default: "Payment confirmed. Tasks are now active."), status: :see_other
    else
      redirect_to cart_path, alert: t("cart.payment_pending", default: "Payment is not completed yet."), status: :see_other
    end
  end

  def cancel
    token = params[:token].to_s
    payment = Payment.where("metadata ->> 'cart_cancel_token' = ?", token).first

    unless payment
      redirect_to cart_path, alert: t("cart.payment_cancel_unknown", default: "Payment session not found."), status: :see_other and return
    end

    if payment.payable_type == "User" && payment.payable_id == current_user.id
      payment.update!(gateway_status: "canceled") unless payment.gateway_status_succeeded?
    end

    redirect_to cart_path, alert: t("cart.payment_canceled", default: "Payment canceled."), status: :see_other
  end

  private

  def set_cart
    @cart = Cart.for(current_user)
  end

  def require_cart_owner!
    return if current_user&.admin? || current_user&.support_agent? || current_user&.manager? || current_user&.sender_role? || current_user&.lawyer? || current_user&.ecommerce_seller?

    redirect_to root_path, alert: t("messages.unauthorized", default: "You are not authorized to perform this action."), status: :see_other
  end

  def authorize_cart_task!(task)
    return if current_user&.admin? || current_user&.support_agent? || current_user&.manager? || task.created_by_id == current_user.id

    raise ActionController::RoutingError, "Not Found"
  end

  def extract_amounts_param
    raw = params[:items]
    return {} unless raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)

    raw.to_unsafe_h.to_h
  rescue
    {}
  end

  def amount_cents_for_task(task, per_task_amounts)
    task_hash = per_task_amounts[task.id.to_s] || {}
    raw_amount = task_hash["amount"].presence
    return parse_amount_cents(raw_amount) if raw_amount.present?

    cost = CostCalculator.new(task).total_cost
    return 0 unless cost.present? && cost.positive?

    parse_amount_cents(format("%.2f", cost))
  end

  def parse_amount_cents(amount_value)
    amount = BigDecimal(amount_value.to_s)
    (amount * 100).to_i
  rescue ArgumentError, TypeError
    0
  end

  def cleanup_published_items
    @cart.cart_items.joins(:task).where(tasks: { published: true }).destroy_all
  end

  def cart_success_template_url
    "#{success_cart_url}?session_id={CHECKOUT_SESSION_ID}"
  rescue
    "#{ENV.fetch("APP_BASE_URL", "http://localhost:3000")}/cart/success?session_id={CHECKOUT_SESSION_ID}"
  end

  def cart_cancel_url_for(token)
    cancel_cart_url(token: token)
  rescue
    "#{ENV.fetch("APP_BASE_URL", "http://localhost:3000")}/cart/cancel?token=#{token}"
  end
end
