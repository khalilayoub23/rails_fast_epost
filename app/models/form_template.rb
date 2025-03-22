class FormTemplate < ApplicationRecord
  belongs_to :carrier
  belongs_to :customer

  validates :carrier, presence: true
  validates :customer, presence: true
end
