class Payment < ApplicationRecord
  has_many :payments_tasks
  has_many :tasks, through: :payments_tasks # ✅ Many-to-Many via payments_tasks
  belongs_to :payable, polymorphic: true

  validates :category, presence: true, numericality: { only_integer: true }
  validates :payment_type, presence: true, numericality: { only_integer: true }
  validates :interval_start, presence: true
  validates :interval_end, presence: true
end