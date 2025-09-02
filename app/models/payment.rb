class Payment < ApplicationRecord
  has_many :payments_tasks
  has_many :tasks, through: :payments_tasks
  belongs_to :payable, polymorphic: true

  # Define category enum
  enum category: {
    service_fee: 0,
    delivery_fee: 1,
    insurance: 2,
    penalty: 3
  }

  # Define payment_type enum
  enum payment_type: {
    per_task: 0,
    lump_sum: 1
  }

  validates :category, presence: true
  validates :payment_type, presence: true
  validates :interval_start, allow_nil: true
  validates :interval_end, allow_nil: true
end