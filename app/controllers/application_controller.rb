class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :allow_github_codespaces

  private

  def allow_github_codespaces
    if Rails.env.development?
      request.headers["HTTP_ORIGIN"] = request.base_url if request.headers["HTTP_ORIGIN"].nil?
    end
  end

  def require_admin!
    # Allow if an authenticated admin is present (integrate with Devise/custom auth when available)
    is_user_admin = respond_to?(:current_user) && current_user && current_user.respond_to?(:admin?) && current_user.admin?
    allowed = is_user_admin || ActiveModel::Type::Boolean.new.cast(ENV["ENABLE_ADMIN_ACTIONS"]) || Rails.env.development? || Rails.env.test?
    return if allowed
    render plain: "Forbidden", status: :forbidden
  end
end
