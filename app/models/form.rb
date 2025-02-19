class Form < ApplicationRecord
  belongs_to :customer

  validates :address, presence: true
  validates :form_default_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
end
