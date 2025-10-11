module Gateways
  class BaseGateway
    include Retryable

    def self.create_intent!(amount_cents:, currency:, task: nil, customer: nil, metadata: {})
      raise NotImplementedError
    end

    def self.process_webhook!(payload:, headers: {})
      raise NotImplementedError
    end

    # Wrap gateway calls with network retry
    def self.with_gateway_retry(&block)
      new.with_network_retry(max_attempts: 3, &block)
    end
  end
end
