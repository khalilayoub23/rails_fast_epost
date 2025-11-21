module Customers
  class NotificationPreferencesController < NotificationPreferencesControllerBase
    self.notifiable_model = Customer
  end
end
