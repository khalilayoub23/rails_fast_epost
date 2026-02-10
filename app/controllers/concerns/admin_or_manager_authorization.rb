module AdminOrManagerAuthorization
  extend ActiveSupport::Concern

  private

  def require_admin_or_manager!
    return if current_user&.admin? || current_user&.manager?

    redirect_to root_path, alert: "Access denied"
  end
end
