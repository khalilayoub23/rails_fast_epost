class CarrierMembership < ApplicationRecord
  belongs_to :user
  belongs_to :carrier

  validates :user_id, uniqueness: { scope: :carrier_id }
end
