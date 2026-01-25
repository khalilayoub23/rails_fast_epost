module Messengers
  class NotificationPreferencesController < NotificationPreferencesControllerBase
    self.notifiable_model = Messenger
    include AdminOrManagerAuthorization

    before_action :require_admin_or_manager!
  end
end
