class PaymentsSyncJob < ApplicationJob
  include Retryable

  queue_as :default

  # Automatically retry the job on failure
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform
    Payment.where(provider: "stripe", gateway_status: :pending).find_each(batch_size: 100) do |payment|
      # Wrap individual payment sync in retry logic
      with_network_retry(max_attempts: 3) do
        Gateways::StripeGateway.sync!(payment: payment)
      end
    rescue => e
      Rails.logger.error("[PaymentsSyncJob] Failed for payment ##{payment.id} after retries: #{e.message}")
      # Continue with next payment instead of failing the entire job
    end
  end
end
