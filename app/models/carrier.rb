class Carrier < ApplicationRecord
  # Use a descriptive column name for carrier kind to avoid STI conflicts.
  # The DB migration renames `type` -> `carrier_type` and tests/fixtures must
  # use `carrier_type` going forward.

  has_many :phones
  has_many :documents
  has_many :form_templates
  has_many :tasks
  has_one :preference

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :carrier_type, presence: true
  validates :address, presence: true
end
