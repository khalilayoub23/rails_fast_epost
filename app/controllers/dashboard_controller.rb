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
    # For admin, use all payments instead of policy_scope to show everything
    payments_scope = safe_relation(apply_payment_filters(Payment.all), Payment)
    tasks_scope = safe_relation(apply_task_filters(policy_scope(Task)), Task)
    deliveries_scope = safe_relation(apply_delivery_filters(policy_scope(Delivery)), Delivery)

    @currency_code = payments_scope.where.not(currency: [ nil, "" ]).distinct.limit(1).pick(:currency) || default_currency_code

    @payments_count = payments_scope.count
    @pending_payments = payments_scope.where(gateway_status: :pending)
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

    load_time_series_metrics(payments_scope: payments_scope, tasks_scope: tasks_scope)
  end

  def load_carrier_data
    @dashboard_view = "carrier"
    load_filter_options
    # Ensure we have a carrier context
    return unless current_carrier_context

    @payouts = current_carrier_context.carrier_payouts
    @currency_code = @payouts.where.not(currency: [ nil, "" ]).distinct.limit(1).pick(:currency) || default_currency_code
    @payouts_count = @payouts.count
    @pending_payouts = @payouts.where(status: :pending).limit(5)
    @recent_payouts = @payouts.order(created_at: :desc).limit(5)
    @earnings_total_cents = @payouts.where(status: :paid).sum(:amount_cents).to_i
    tasks_scope = apply_task_filters(policy_scope(Task))
    @completed_tasks_count = tasks_scope.where(status: :delivered).count
    @recent_tasks = tasks_scope.order(created_at: :desc).limit(5)
    @task_filters = task_filter_params

    # Carrier dashboard focuses on payouts/tasks, but keep chart/target widgets populated if present.
    load_time_series_metrics(payments_scope: Payment.none, tasks_scope: tasks_scope)
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

    payments_scope = safe_relation(policy_scope(Payment), Payment)
    @currency_code = payments_scope.where.not(currency: [ nil, "" ]).distinct.limit(1).pick(:currency) || default_currency_code
    load_time_series_metrics(payments_scope: payments_scope, tasks_scope: tasks_scope)
  end

  def load_sender_data
    @dashboard_view = "sender"
    load_filter_options(minimal: true)
    Rails.logger.info("[Dashboard] load_sender_data for #{current_user&.email} (role: #{current_user&.role})")

    # For lawyers, filter by lawyer_id; for senders, filter by sender_id
    if current_user.lawyer?
      lawyer_profile = current_user.ensure_lawyer_profile!

      unless lawyer_profile
        @my_payments = Payment.none
        @payments_count = 0
        @pending_payments = Payment.none
        @recent_payments = Payment.none
        @total_spend_cents = 0
        @refunds_total_cents = 0
        @tasks_count = 0
        @recent_tasks = Task.none
        @customers_count = 0
        @currency_code = default_currency_code
        load_time_series_metrics(payments_scope: Payment.none, tasks_scope: Task.none)
        return
      end

      # Filter payments for tasks assigned to this lawyer
      payments_scope = Payment.joins(:task).where(tasks: { lawyer_id: lawyer_profile.id })
      payments_scope = safe_relation(payments_scope, Payment)
      @my_payments = apply_payment_filters(payments_scope)

      @currency_code = @my_payments.where.not(currency: [ nil, "" ]).distinct.limit(1).pick(:currency) || default_currency_code

      @payments_count = @my_payments.count
      @pending_payments = @my_payments.where(gateway_status: :pending).limit(5)
      @recent_payments = @my_payments.order(created_at: :desc).limit(5)
      @total_spend_cents = @my_payments.where(gateway_status: :succeeded).sum(:amount_cents).to_i
      @refunds_total_cents = Refund.where(payment_id: @my_payments.select(:id)).sum(:amount_cents).to_i
      task_scope = safe_relation(apply_task_filters(policy_scope(Task)), Task)
      @tasks_count = task_scope.where(lawyer_id: lawyer_profile.id).count
      @recent_tasks = task_scope.where(lawyer_id: lawyer_profile.id).order(created_at: :desc).limit(5)
      @customers_count = Customer.joins(:tasks).where(tasks: { lawyer_id: lawyer_profile.id }).distinct.count
      @task_filters = task_filter_params
      @payment_filters = payment_filter_params

      load_time_series_metrics(payments_scope: @my_payments, tasks_scope: task_scope.where(lawyer_id: lawyer_profile.id))
    else
      # Filter payments for tasks where the current user is the sender (use Payment.none as fallback)
      payments_scope = Payment.joins(:task).where(tasks: { sender_id: current_user.id })
      payments_scope = safe_relation(payments_scope, Payment)
      @my_payments = apply_payment_filters(payments_scope)

      @currency_code = @my_payments.where.not(currency: [ nil, "" ]).distinct.limit(1).pick(:currency) || default_currency_code

      @payments_count = @my_payments.count
      @pending_payments = @my_payments.where(gateway_status: :pending).limit(5)
      @recent_payments = @my_payments.order(created_at: :desc).limit(5)
      @total_spend_cents = @my_payments.where(gateway_status: :succeeded).sum(:amount_cents).to_i
      @refunds_total_cents = Refund.where(payment_id: @my_payments.select(:id)).sum(:amount_cents).to_i
      task_scope = safe_relation(apply_task_filters(policy_scope(Task)), Task)
      @tasks_count = task_scope.where(sender_id: current_user.id).count
      @recent_tasks = task_scope.where(sender_id: current_user.id).order(created_at: :desc).limit(5)
      @customers_count = Customer.joins(:tasks).where(tasks: { sender_id: current_user.id }).distinct.count
      @task_filters = task_filter_params
      @payment_filters = payment_filter_params

      load_time_series_metrics(payments_scope: @my_payments, tasks_scope: task_scope.where(sender_id: current_user.id))
    end
  end

  def load_manager_data
    @dashboard_view = "manager"
    load_admin_data
    @dashboard_view = "manager"
  end

  def load_time_series_metrics(payments_scope:, tasks_scope:)
    payments_scope = safe_relation(payments_scope, Payment)
    tasks_scope = safe_relation(tasks_scope, Task)

    now = Time.zone.now
    month_start = now.beginning_of_month
    today_range = now.beginning_of_day..now.end_of_day

    @today_revenue_cents = payments_scope.where(gateway_status: :succeeded, created_at: today_range).sum(:amount_cents).to_i
    @month_revenue_cents = payments_scope.where(gateway_status: :succeeded, created_at: month_start..now).sum(:amount_cents).to_i

    @monthly_target_cents = env_monthly_target_cents
    if @monthly_target_cents.to_i <= 0
      @monthly_target_cents = inferred_monthly_target_cents(payments_scope)
    end

    @target_percent = if @monthly_target_cents.to_i > 0
      ((@month_revenue_cents.to_f / @monthly_target_cents) * 100).clamp(0, 100).round
    else
      0
    end

    last_month_start = (month_start - 1.month).beginning_of_month
    last_month_end = (month_start - 1.month).end_of_month
    last_month_revenue_cents = payments_scope.where(gateway_status: :succeeded, created_at: last_month_start..last_month_end).sum(:amount_cents).to_i
    @target_delta_percent = if last_month_revenue_cents.positive?
      (((@month_revenue_cents - last_month_revenue_cents).to_f / last_month_revenue_cents) * 100).round
    else
      0
    end

    @chart_series_a_by_period = {
      "day" => last_12_day_buckets { |range| payments_scope.where(gateway_status: :succeeded, created_at: range).count },
      "week" => last_12_week_buckets { |range| payments_scope.where(gateway_status: :succeeded, created_at: range).count },
      "month" => last_12_month_buckets { |range| payments_scope.where(gateway_status: :succeeded, created_at: range).count }
    }
    @chart_series_b_by_period = {
      "day" => last_12_day_buckets { |range| tasks_scope.where(created_at: range).count },
      "week" => last_12_week_buckets { |range| tasks_scope.where(created_at: range).count },
      "month" => last_12_month_buckets { |range| tasks_scope.where(created_at: range).count }
    }

    @chart_range_label = I18n.t("dashboard.chart_range_label", default: "Last 12")
  end

  def last_12_day_buckets
    now = Time.zone.now
    starts = 11.downto(0).map { |i| (now.to_date - i.days).beginning_of_day.in_time_zone }
    starts.map do |start_time|
      end_time = start_time.end_of_day
      yield(start_time..end_time)
    end
  end

  def last_12_week_buckets
    now = Time.zone.now
    starts = 11.downto(0).map { |i| (now.beginning_of_week - i.weeks).beginning_of_week }
    starts.map do |start_time|
      end_time = start_time.end_of_week
      yield(start_time..end_time)
    end
  end

  def last_12_month_buckets
    now = Time.zone.now
    starts = 11.downto(0).map { |i| (now.beginning_of_month - i.months).beginning_of_month }
    starts.map do |start_time|
      end_time = start_time.end_of_month
      yield(start_time..end_time)
    end
  end

  def env_monthly_target_cents
    Integer(ENV.fetch("DASHBOARD_MONTHLY_TARGET_CENTS", "0"), 10)
  rescue ArgumentError
    0
  end

  def inferred_monthly_target_cents(payments_scope)
    now = Time.zone.now
    # Average of the last 3 full months; fallback to a sane default.
    starts = 3.downto(1).map { |i| (now.beginning_of_month - i.months).beginning_of_month }
    totals = starts.map do |start_time|
      payments_scope.where(gateway_status: :succeeded, created_at: start_time..start_time.end_of_month).sum(:amount_cents).to_i
    end
    avg = totals.sum / [ totals.count, 1 ].max
    avg.positive? ? avg : 2_000_000
  end

  def safe_relation(scope, model_class)
    scope || model_class.none
  end

  def default_currency_code
    ENV.fetch("DEFAULT_CURRENCY", "ILS")
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
