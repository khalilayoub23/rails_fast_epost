class CarrierPayoutSyncJob < ApplicationJob
  include Retryable

  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(purge: false)
    CarrierPayoutSync.call(purge: purge)
  end
end
