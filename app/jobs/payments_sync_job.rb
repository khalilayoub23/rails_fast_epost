class PaymentsSyncJob < ApplicationJob
  queue_as :default

  def perform
    Payment.where(provider: "stripe", gateway_status: :pending).find_each(batch_size: 100) do |payment|
      begin
        Gateways::StripeGateway.sync!(payment: payment)
      rescue => e
        Rails.logger.warn("PaymentsSyncJob failed for payment ##{payment.id}: #{e.message}")
      end
    end
  end
end
