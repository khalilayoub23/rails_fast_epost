module Admin
  class DashboardController < ApplicationController
    before_action :require_admin!

    def index
      @payments_count = Payment.count
      @customers_count = Customer.count
      @revenue_total_cents = Payment.where(gateway_status: :succeeded).sum(:amount_cents).to_i
    end

    private

    def require_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: "You are not authorized to access admin."
      end
    end
  end
end
