# SmsDelivery wraps Twilio (or a stub) so NotificationService can stay decoupled.
class SmsDelivery
  class << self
    Response = Struct.new(:sid, :status, keyword_init: true)

    def deliver!(to:, body:, metadata: {})
      return record_skip("missing phone", metadata) if to.blank?
      return record_skip("sms disabled", metadata.merge(reason: "missing configuration")) unless enabled?

      response = client.messages.create(
        from: sender_number,
        to: to,
        body: body
      )

      Response.new(sid: response.sid, status: response.status)
    rescue StandardError => e
      Rails.logger.error "[SmsDelivery] Failed to send SMS: #{e.class}: #{e.message}"
      raise e
    end

    def enabled?
      sender_number.present? && ENV["TWILIO_ACCOUNT_SID"].present? && ENV["TWILIO_AUTH_TOKEN"].present?
    end

    private

    def sender_number
      ENV["TWILIO_PHONE_NUMBER"]
    end

    def client
      @client ||= Twilio::REST::Client.new
    end

    def record_skip(reason, metadata)
      Rails.logger.info "[SmsDelivery] Skipping SMS: #{reason} #{metadata}"
      Response.new(sid: nil, status: :skipped)
    end
  end
end
