module Senders
  class NotificationPreferencesController < NotificationPreferencesControllerBase
    self.notifiable_model = Sender
    include AdminOrManagerAuthorization

    before_action :require_admin_or_manager!
  end
end
