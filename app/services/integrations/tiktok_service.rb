module Integrations
  class TiktokService
    def self.process(payload, headers: {}, signature_valid: false)
      external_id = IdExtractor.extract(provider: "tiktok", payload: payload, headers: headers)
      event = BaseService.record_event(provider: "tiktok", headers: headers, body: payload, signature_valid: signature_valid, external_id: external_id)
      return true if event.status_processed?
      success, _ = EventMapper.map(provider: "tiktok", payload: payload, headers: headers)
      BaseService.mark_processed!(event, success)
      success
    end
  end
end
