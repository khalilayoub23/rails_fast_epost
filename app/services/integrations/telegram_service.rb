module Integrations
  class TelegramService
    def self.process(payload, headers: {}, signature_valid: false)
      external_id = IdExtractor.extract(provider: "telegram", payload: payload, headers: headers)
      event = BaseService.record_event(provider: "telegram", headers: headers, body: payload, signature_valid: signature_valid, external_id: external_id)
      return true if event.status_processed?
      success, _ = EventMapper.map(provider: "telegram", payload: payload, headers: headers)
      BaseService.mark_processed!(event, success)
      success
    end
  end
end
