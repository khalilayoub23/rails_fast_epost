class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :allow_github_codespaces
  before_action :set_current_user

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

  def require_manager!
    is_manager = respond_to?(:current_user) && current_user && (current_user.respond_to?(:manager?) && current_user.manager?)
    allowed = is_manager || ActiveModel::Type::Boolean.new.cast(ENV["ENABLE_ADMIN_ACTIONS"]) || Rails.env.development? || Rails.env.test?
    return if allowed
    render plain: "Forbidden", status: :forbidden
  end

  def current_user
    Current.user
  end

  helper_method :current_user

  def set_current_user
    # Demo-only role simulation: ADMIN, MANAGER, or VIEWER
    role = (ENV["DEMO_ROLE"] || "ADMIN").to_s.upcase
    user = Struct.new(:name, :role) do
      def admin? = role == "ADMIN"
      def manager? = role == "MANAGER" || admin?
      def viewer? = role == "VIEWER"
    end
    Current.user = user.new("Demo User", role)
  end
end
