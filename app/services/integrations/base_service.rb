module Integrations
  class BaseService
    def self.record_event(provider:, headers:, body:, signature_valid:, external_id: nil)
      if external_id.present?
        existing = IntegrationEvent.find_by(provider: provider, external_id: external_id)
        return existing if existing
      end

      IntegrationEvent.create!(
        provider: provider,
        headers: headers,
        body: body,
        signature_valid: signature_valid,
        status: "received",
        external_id: external_id
      )
    end

    def self.mark_processed!(event, success)
      if success
        event.update!(status: "processed", processed_at: Time.current)
      else
        event.update!(status: "failed", processed_at: Time.current)
      end
    end
  end
end
