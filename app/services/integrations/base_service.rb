module Integrations
  class BaseService
    HEADER_EXCLUDE_PREFIXES = %w[rack. action_dispatch. puma. falcon.].freeze

    def self.record_event(provider:, headers:, body:, signature_valid:, external_id: nil)
      if external_id.present?
        existing = IntegrationEvent.find_by(provider: provider, external_id: external_id)
        return existing if existing
      end

      IntegrationEvent.create!(
        provider: provider,
        headers: normalize_headers(headers),
        body: normalize_body(body),
        signature_valid: signature_valid,
        status: "received",
        external_id: external_id
      )
    end

    def self.mark_processed!(event, success)
      return unless event

      if success
        event.update!(status: "processed", processed_at: Time.current)
      else
        event.update!(status: "failed", processed_at: Time.current)
      end
    end

    def self.normalize_headers(headers)
      data = coerce_to_hash(headers)

      data.each_with_object({}) do |(key, value), memo|
        key_str = key.to_s
        next if HEADER_EXCLUDE_PREFIXES.any? { |prefix| key_str.start_with?(prefix) }
        memo[key_str] = safe_value(value)
      end
    rescue => e
      Rails.logger.warn("[Integrations::BaseService] Failed to normalize headers: #{e.message}")
      {}
    end

    def self.normalize_body(body)
      data = coerce_to_hash(body)
      safe_value(data)
    rescue => e
      Rails.logger.warn("[Integrations::BaseService] Failed to normalize body: #{e.message}")
      {}
    end

    def self.coerce_to_hash(value)
      return {} if value.nil?
      return value if value.is_a?(Hash)
      return value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      return value.to_h if value.respond_to?(:to_h)

      {}
    end

    def self.safe_value(value)
      case value
      when Hash
        value.each_with_object({}) do |(k, v), memo|
          memo[k.to_s] = safe_value(v)
        end
      when Array
        value.map { |entry| safe_value(entry) }
      when String, Numeric, TrueClass, FalseClass, NilClass
        value
      else
        if value.respond_to?(:to_s)
          value.to_s
        else
          value.inspect
        end
      end
    end

    private_class_method :normalize_headers, :normalize_body, :coerce_to_hash, :safe_value
  end
end
