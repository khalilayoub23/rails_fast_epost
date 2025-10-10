class DashboardController < ApplicationController
  def index
    @payments_count = Payment.count
    @pending_payments = Payment.where(gateway_status: :pending).limit(5)
    @recent_payments = Payment.order(created_at: :desc).limit(5)
    @recent_tasks = Task.order(created_at: :desc).limit(5)
    @revenue_total_cents = Payment.where(gateway_status: :succeeded).sum(:amount_cents).to_i
    @refunds_total_cents  = Refund.sum(:amount_cents).to_i
    @customers_count = Customer.count
  end
end
