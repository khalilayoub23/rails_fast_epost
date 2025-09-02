class Task < ApplicationRecord
  belongs_to :customer
  belongs_to :carrier
  has_many :payments_tasks
  has_many :payments, through: :payments_tasks
  has_one :cost_calc
  has_many :remarks

  # Define failure_code enum
  enum failure_code: {
    no_failure: 0,
    address_not_found: 1,
    recipient_unavailable: 2,
    package_damaged: 3,
    refused_delivery: 4
  }, _prefix: true

  # Define status enum
  enum status: {
    pending: 0,
    in_transit: 1,
    delivered: 2,
    failed: 3,
    returned: 4
  }

  validates :package_type, presence: true
  validates :start, presence: true
  validates :target, presence: true
  validates :delivery_time, presence: true
  validates :status, presence: true
  validates :barcode, presence: true, uniqueness: true
  validates :filled_form_url, allow_nil: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
end
