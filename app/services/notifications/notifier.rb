module Notifications
  class Notifier
    attr_reader :task, :actor

    def initialize(task: nil, actor: nil)
      @task = task
      @actor = actor
    end

    private

    def email_allowed?(record)
      contactable?(record) && channel_enabled?(record, :email)
    end

    def sms_allowed?(record)
      sms_contactable?(record) && channel_enabled?(record, :sms)
    end

    def contactable?(record)
      record.present? && record.respond_to?(:email) && record.email.present?
    end

    def sms_contactable?(record)
      record.present? && record.respond_to?(:phone) && record.phone.present?
    end

    def channel_enabled?(record, channel)
      return false if record.blank?

      preference = NotificationPreference.lookup(record, channel)
      default_enabled = channel == :email

      if preference.nil?
        return default_enabled
      end

      preference.enabled? && !preference.quiet_hours_active?
    end

    def deliver_email(mailer, message_type:, notifiable:)
      Notifications::Delivery.email(mailer, message_type: message_type, notifiable: notifiable)
    end

    def deliver_sms(recipient:, message_type:, body:)
      Notifications::Delivery.sms(recipient: recipient, message_type: message_type, body: body)
    end
  end
end
