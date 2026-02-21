module Gateways
  class LocalGateway < BaseGateway
    PROVIDER = "local".freeze

    # Create a local payment using the existing Payment model; generate a pseudo external ID and URL
    def self.create_payment!(amount_cents:, currency:, task:, payable:, metadata: {})
      external_id = SecureRandom.uuid
      Payment.create!(
        provider: PROVIDER,
        external_id: external_id,
        amount_cents: amount_cents,
        currency: currency,
        task: task,
        payable: payable,
        payment_url: "/pay/local/#{external_id}",
        metadata: metadata,
        gateway_status: "pending",
        category: :service_fee,
        payment_type: :per_task
      )
    end

    # Expected headers: X-Signature: base64(HMAC-SHA256(secret, raw_body))
    def self.process_webhook!(payload:, headers: {})
      secret = ENV["LOCALPAY_APP_SECRET"].to_s
      signature = headers["X-Signature"].to_s
      raw = headers["__raw_body__"].to_s # optional passthrough of raw body

      if secret.present? && signature.present? && raw.present?
        computed = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, raw))
        raise "Invalid signature" unless secure_token_match?(computed, signature)
      end

      external_id = payload["external_id"].presence || payload["id"].presence
      status = payload["status"].to_s.presence || "succeeded"
      payment = Payment.find_by(provider: PROVIDER, external_id: external_id)
      return nil unless payment

      payment.update!(gateway_status: status)
      if status == "succeeded" && payment.task_id
        Remark.create!(task_id: payment.task_id, remarkable: payment, content: "Local payment succeeded: #{payment.external_id}")
      end
      payment
    end

    def self.secure_token_match?(expected, provided)
      left = expected.to_s
      right = provided.to_s
      return false if left.blank? || right.blank?
      return false unless left.bytesize == right.bytesize

      ActiveSupport::SecurityUtils.secure_compare(left, right)
    end
    private_class_method :secure_token_match?
  end
end
