class Carrier < ApplicationRecord
  # Use a descriptive column name for carrier kind to avoid STI conflicts.
  # The DB migration renames `type` -> `carrier_type` and tests/fixtures must
  # use `carrier_type` going forward.

  has_many :phones, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :form_templates, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_one :preference, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :carrier_type, presence: true
  validates :address, presence: true
end
