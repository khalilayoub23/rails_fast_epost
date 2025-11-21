module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notification_preferences, as: :notifiable, dependent: :destroy
    has_many :notification_logs, as: :notifiable, dependent: :nullify
  end

  # Returns the preferred notification channel for the record, falling back to email.
  def preferred_notification_channel
    notification_preferences.enabled.order(:channel).first&.channel&.to_sym || :email
  end
end
