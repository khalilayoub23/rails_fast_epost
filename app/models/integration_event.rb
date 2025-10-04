class IntegrationEvent < ApplicationRecord
  enum :status, { received: "received", processed: "processed", failed: "failed" }, prefix: true

  validates :provider, presence: true
  validates :external_id, uniqueness: { scope: :provider }, allow_nil: true
end
