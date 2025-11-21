module Notifications
  class Delivery
    class << self
      def email(mailer, message_type:, notifiable:)
        deliver(mailer, channel: :email, message_type: message_type, notifiable: notifiable) do
          if Rails.env.test?
            mailer.deliver_now
          else
            mailer.deliver_later
          end
        end
      end

      def sms(recipient:, message_type:, body:)
        response = SmsDelivery.deliver!(
          to: phone_number_for(recipient),
          body: body,
          metadata: { recipient_id: recipient.try(:id), message_type: message_type }
        )

        status_value = response.status.to_s == NotificationLog::STATUSES[:skipped] ? NotificationLog::STATUSES[:skipped] : NotificationLog::STATUSES[:sent]

        NotificationLog.record!(
          message_type: message_type,
          channel: :sms,
          status: status_value,
          notifiable: recipient,
          provider_message_id: response.sid,
          metadata: { body_preview: body.to_s.truncate(140) }
        )
      rescue StandardError => e
        NotificationLog.record!(
          message_type: message_type,
          channel: :sms,
          status: NotificationLog::STATUSES[:failed],
          notifiable: recipient,
          metadata: { error: e.message }
        )
      end

      private

      def deliver(mailer, channel:, message_type:, notifiable:)
        yield

        NotificationLog.record!(
          message_type: message_type,
          channel: channel,
          status: NotificationLog::STATUSES[:sent],
          notifiable: notifiable
        )
      rescue StandardError => e
        NotificationLog.record!(
          message_type: message_type,
          channel: channel,
          status: NotificationLog::STATUSES[:failed],
          notifiable: notifiable,
          metadata: { error: e.message }
        )
        Rails.logger.error "[NotificationService] #{channel.upcase} delivery failed: #{e.message}"
      end

      def phone_number_for(record)
        return nil if record.blank?

        if record.respond_to?(:phone)
          record.phone
        elsif record.respond_to?(:phones)
          Array(record.phones).first
        end
      end
    end
  end
end
