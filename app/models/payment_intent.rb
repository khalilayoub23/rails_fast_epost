class PaymentIntent < ApplicationRecord
  enum :status, {
    created: "created",
    pending: "pending",
    succeeded: "succeeded",
    failed: "failed",
    canceled: "canceled"
  }, prefix: true

  belongs_to :task, optional: true
  belongs_to :customer, optional: true

  validates :provider, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true
  validates :external_id, uniqueness: { scope: :provider }, allow_nil: true
end
