module CourtForms
  class DeliveryFormComponent < ApplicationComponent
    attr_reader :delivery, :qr_code_data_uri

    def initialize(delivery:, qr_code_data_uri:)
      @delivery = delivery
      @qr_code_data_uri = qr_code_data_uri
    end

    def sender
      delivery.sender
    end

    def courier
      delivery.courier
    end

    def recipient
      delivery.recipient
    end

    def formatted_created_at
      delivery.created_at.in_time_zone("Asia/Jerusalem").strftime("%d.%m.%Y %H:%M")
    rescue StandardError
      delivery.created_at&.to_s
    end
  end
end
