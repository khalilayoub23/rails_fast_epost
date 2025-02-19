class Task < ApplicationRecord
  belongs_to :customer
  belongs_to :carrier
  has_many :payments_tasks
  has_many :payments, through: :payments_tasks
  has_one :cost_calc
  has_many :remarks

  validates :package_type, presence: true
  validates :start, presence: true
  validates :target, presence: true
  validates :failure_code, numericality: { only_integer: true }, allow_nil: true
  validates :delivery_time, presence: true
  validates :status, presence: true, numericality: { only_integer: true }
  validates :barcode, presence: true, uniqueness: true
  validates :filled_form_url, allow_nil: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
end
