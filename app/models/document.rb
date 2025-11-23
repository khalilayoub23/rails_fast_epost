class Document < ApplicationRecord
  CARRIER_SIGNATURE_ID = "carrier_signature".freeze

  belongs_to :carrier

  scope :carrier_signatures, -> { where(id_document: CARRIER_SIGNATURE_ID) }

  validates :id_document, presence: true, uniqueness: { scope: :carrier_id }
  validates :signature, presence: true
end
