class WhatsappNotifier
  def self.notify(number:, message:)
    sender = ENV["WHATSAPP_SENDER_NUMBER"]
    return false if sender.blank? || number.blank?

    Rails.logger.info("[WhatsApp] To: #{number} - #{message}")
    true
  end
end
