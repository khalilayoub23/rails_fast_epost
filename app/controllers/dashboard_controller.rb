class DashboardController < ApplicationController
  def index
    @payments_count = Payment.count
    @pending_payments = Payment.where(gateway_status: :pending).limit(5)
    @recent_tasks = Task.order(created_at: :desc).limit(5)
  end
end
