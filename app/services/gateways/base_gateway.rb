module Gateways
  class BaseGateway
    def self.create_intent!(amount_cents:, currency:, task: nil, customer: nil, metadata: {})
      raise NotImplementedError
    end

    def self.process_webhook!(payload:, headers: {})
      raise NotImplementedError
    end
  end
end
