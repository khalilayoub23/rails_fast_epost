class Payment < ApplicationRecord
  has_many :payments_tasks
  has_many :payments_tasks, dependent: :destroy
  has_many :tasks, through: :payments_tasks
  belongs_to :payable, polymorphic: true
  # Associate payment to a primary task — fixtures reference tasks by label (task: one)
  # The payments table already has a task_id column and a foreign key to tasks.
  belongs_to :task

  # Define category enum (positional syntax)
  enum :category, { service_fee: 0, delivery_fee: 1, insurance: 2, penalty: 3 }

  # Define payment_type enum (positional syntax)
  enum :payment_type, { per_task: 0, lump_sum: 1 }

  validates :category, presence: true
  validates :payment_type, presence: true
  # interval_start and interval_end are optional datetime fields; no extra validation required
end