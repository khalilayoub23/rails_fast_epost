module Admin
  class DashboardController < ApplicationController
    before_action :require_admin!

    def index
      redirect_to dashboard_path
    end

    private

    def require_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: "You are not authorized to access admin."
      end
    end
  end
end
