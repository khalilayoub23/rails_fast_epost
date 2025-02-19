class Task < ApplicationRecord
  belongs_to :customer
  belongs_to :carrier
  has_many :payments_tasks
  has_many :payments, through: :payments_tasks
  has_one :cost_calc
  has_many :remarks
end
