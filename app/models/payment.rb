class Payment < ApplicationRecord
  has_many :payments_tasks
  has_many :tasks, through: :payments_tasks # ✅ Many-to-Many via payments_tasks
  belongs_to :payable, polymorphic: true
end