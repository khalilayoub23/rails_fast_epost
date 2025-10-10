class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :allow_github_codespaces
  before_action :authenticate_user!
  before_action :set_current_attributes

  private

  def allow_github_codespaces
    if Rails.env.development?
      request.headers["HTTP_ORIGIN"] = request.base_url if request.headers["HTTP_ORIGIN"].nil?
    end
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end

  def require_manager!
    unless current_user&.manager?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end

  # Set Current.user for use in models/jobs
  def set_current_attributes
    Current.user = current_user
  end
end
