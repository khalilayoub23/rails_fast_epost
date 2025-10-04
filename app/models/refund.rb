class Refund < ApplicationRecord
  belongs_to :payment

  validates :provider, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
