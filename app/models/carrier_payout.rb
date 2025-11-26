class CarrierPayout < ApplicationRecord
  belongs_to :carrier
  belongs_to :task

  enum :status, {
    pending: "pending",
    scheduled: "scheduled",
    paid: "paid",
    disputed: "disputed"
  }, default: :pending

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  scope :outstanding, -> { where.not(status: :paid) }
  scope :cleared, -> { where(status: :paid) }

  def amount
    amount_cents.to_i / 100.0
  end
end
