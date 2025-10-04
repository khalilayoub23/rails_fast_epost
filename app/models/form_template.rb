class FormTemplate < ApplicationRecord
  belongs_to :carrier
  belongs_to :customer

  validates :carrier, presence: true
  validates :customer, presence: true
  validate :schema_is_hash

  # Minimal contract: schema is a Hash describing fields and positions
  # Example:
  # {
  #   "title": "Delivery Form",
  #   "fields": [
  #     {"name": "customer_name", "x": 50, "y": 760, "font_size": 12},
  #     {"name": "address", "x": 50, "y": 740}
  #   ]
  # }

  def schema_is_hash
    errors.add(:schema, "must be an object") unless schema.is_a?(Hash)
  end
end
