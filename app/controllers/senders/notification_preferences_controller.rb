module Senders
  class NotificationPreferencesController < NotificationPreferencesControllerBase
    self.notifiable_model = Sender

    before_action :require_admin_or_manager!

    private

    def require_admin_or_manager!
      unless current_user&.admin? || current_user&.manager?
        redirect_to root_path, alert: "Access denied"
      end
    end
  end
end
