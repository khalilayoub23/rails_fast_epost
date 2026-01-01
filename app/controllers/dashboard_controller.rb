class DashboardController < ApplicationController
  def index
    if current_user.admin?
      load_admin_data
    elsif current_user.manager?
      load_manager_data
    elsif current_user.carrier_staff?
      load_carrier_data
    elsif current_user.support_agent? || current_user.warehouse_agent?
      load_operational_data
    else
      authorize :viewer, :access_dashboard?
      load_sender_data
    end
  end

  private

  def load_admin_data
    @dashboard_view = "admin"
    load_filter_options
    payments_scope = safe_relation(apply_payment_filters(policy_scope(Payment)), Payment)
    tasks_scope = safe_relation(apply_task_filters(policy_scope(Task)), Task)
    deliveries_scope = safe_relation(apply_delivery_filters(policy_scope(Delivery)), Delivery)

    @payments_count = payments_scope.count
    @pending_payments = payments_scope.where(gateway_status: :pending).limit(5)
    @recent_payments = payments_scope.order(created_at: :desc).limit(5)
    @recent_tasks = tasks_scope.order(created_at: :desc).limit(5)
    @revenue_total_cents = payments_scope.where(gateway_status: :succeeded).sum(:amount_cents).to_i
    @refunds_total_cents  = Refund.where(payment_id: payments_scope.select(:id)).sum(:amount_cents).to_i
    @customers_count = Customer.count
    @deliveries_count = deliveries_scope.count
    @delivery_filters = delivery_filter_params
    @task_filters = task_filter_params
    @payment_filters = payment_filter_params
    @delivery_samples = deliveries_scope.includes(:sender, :recipient, :courier).order(created_at: :desc).limit(5)
  end

  def load_carrier_data
    @dashboard_view = "carrier"
    load_filter_options
    # Ensure we have a carrier context
    return unless current_carrier_context

    @payouts = current_carrier_context.carrier_payouts
    @payouts_count = @payouts.count
    @pending_payouts = @payouts.where(status: :pending).limit(5)
    @recent_payouts = @payouts.order(created_at: :desc).limit(5)
    @earnings_total_cents = @payouts.where(status: :paid).sum(:amount_cents).to_i
    tasks_scope = apply_task_filters(policy_scope(Task))
    @completed_tasks_count = tasks_scope.where(status: :delivered).count
    @recent_tasks = tasks_scope.order(created_at: :desc).limit(5)
    @task_filters = task_filter_params
  end

  def load_operational_data
    @dashboard_view = "operational"
    load_filter_options
    tasks_scope = apply_task_filters(policy_scope(Task))
    deliveries_scope = apply_delivery_filters(policy_scope(Delivery))

    @tasks_count = tasks_scope.count
    @pending_tasks = tasks_scope.where(status: [ :pending, :in_transit ]).limit(5)
    @recent_tasks = tasks_scope.order(created_at: :desc).limit(5)
    @deliveries_count = deliveries_scope.count
    @delivery_filters = delivery_filter_params
    @task_filters = task_filter_params
    @delivery_samples = deliveries_scope.includes(:sender, :recipient, :courier).order(created_at: :desc).limit(5)
  end

  def load_sender_data
    @dashboard_view = "sender"
    load_filter_options(minimal: true)
    Rails.logger.info("[Dashboard] load_sender_data for #{current_user&.email} (role: #{current_user&.role})")
    # Filter payments for tasks where the current user is the sender (use Payment.none as fallback)
    payments_scope = Payment.joins(:task).where(tasks: { sender_id: current_user.id })
    payments_scope = safe_relation(payments_scope, Payment)
    @my_payments = apply_payment_filters(payments_scope)
    
    @payments_count = @my_payments.count
    @pending_payments = @my_payments.where(gateway_status: :pending).limit(5)
    @recent_payments = @my_payments.order(created_at: :desc).limit(5)
    @total_spend_cents = @my_payments.where(gateway_status: :succeeded).sum(:amount_cents).to_i
    @refunds_total_cents = Refund.where(payment_id: @my_payments.select(:id)).sum(:amount_cents).to_i
    task_scope = safe_relation(apply_task_filters(policy_scope(Task)), Task)
    @tasks_count = task_scope.where(sender_id: current_user.id).count
    @recent_tasks = task_scope.where(sender_id: current_user.id).order(created_at: :desc).limit(5)
    @task_filters = task_filter_params
    @payment_filters = payment_filter_params
  end

  def load_manager_data
    @dashboard_view = "manager"
    load_admin_data
    @dashboard_view = "manager"
  end

  def safe_relation(scope, model_class)
    scope || model_class.none
  end

  def load_filter_options(minimal: false)
    @payment_gateways = Payment.distinct.order(:provider).pluck(:provider).compact
    @task_statuses = Task.statuses.keys
    @delivery_statuses = Delivery.statuses.keys

    return if minimal

    @carrier_options = Carrier.order(:name)
    sender_roles = User.user_types.slice(:sender, :lawyer, :ecommerce_seller).values
    @sender_options = User.where(user_type: sender_roles).order(:full_name)
    @courier_options = User.where(user_type: User.user_types[:courier]).order(:full_name)
    @recipient_options = User.where(user_type: User.user_types[:recipient]).order(:full_name)
  end

  def payment_filter_params
    params.fetch(:payment_filter, {}).permit(:status, :gateway, :task_association)
  end

  def task_filter_params
    params.fetch(:task_filter, {}).permit(:status, :carrier_id, :sender_id)
  end

  def delivery_filter_params
    params.fetch(:delivery_filter, {}).permit(:status, :courier_id, :sender_id, :recipient_id)
  end

  def apply_payment_filters(scope)
    filters = payment_filter_params
    scope ||= Payment.none
    scope = scope.where(gateway_status: filters[:status]) if filters[:status].present?
    scope = scope.where(provider: filters[:gateway]) if filters[:gateway].present?

    case filters[:task_association]
    when "with_task"
      scope = scope.where.not(task_id: nil)
    when "without_task"
      scope = scope.where(task_id: nil)
    end

    scope
  end

  def apply_task_filters(scope)
    filters = task_filter_params
    scope ||= Task.none
    scope = scope.where(status: filters[:status]) if filters[:status].present?
    scope = scope.where(carrier_id: filters[:carrier_id]) if filters[:carrier_id].present?
    scope = scope.where(sender_id: filters[:sender_id]) if filters[:sender_id].present?
    scope
  end

  def apply_delivery_filters(scope)
    filters = delivery_filter_params
    scope ||= Delivery.none
    scope = scope.where(status: filters[:status]) if filters[:status].present?
    scope = scope.where(courier_id: filters[:courier_id]) if filters[:courier_id].present?
    scope = scope.where(sender_id: filters[:sender_id]) if filters[:sender_id].present?
    scope = scope.where(recipient_id: filters[:recipient_id]) if filters[:recipient_id].present?
    scope
  end
end
