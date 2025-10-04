class Form < ApplicationRecord
  belongs_to :customer
  belongs_to :form_template, optional: true

  validates :address, presence: true
  validates :form_default_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validate :data_is_hash

  def data_is_hash
    errors.add(:data, "must be an object") unless data.is_a?(Hash)
  end
end
