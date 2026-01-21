class SignatureToken
  DEFAULT_TTL = 30.minutes

  class << self
    def generate(delivery:, user:, role:, expires_in: DEFAULT_TTL)
      payload = {
        delivery_id: delivery.id,
        user_id: user.id,
        role: role.to_s,
        exp: Time.current.advance(seconds: expires_in.to_i).to_i
      }

      verifier.generate(payload)
    end

    def verify(token)
      data = verifier.verify(token)
      return nil unless data.is_a?(Hash)

      exp = data[:exp] || data["exp"]
      return nil if exp.blank? || Time.at(exp) < Time.current

      symbolize_keys(data)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    private

    def verifier
      @verifier ||= ActiveSupport::MessageVerifier.new(secret, serializer: JSON)
    end

    def secret
      Rails.application.key_generator.generate_key("signature_token", 32)
    end

    def symbolize_keys(hash)
      hash.each_with_object({}) do |(k, v), memo|
        memo[k.to_sym] = v
      end
    end
  end
end
