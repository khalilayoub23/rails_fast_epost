class Document < ApplicationRecord
  belongs_to :carrier

  validates :id_document, presence: true, uniqueness: true
  validates :signature, presence: true
end
