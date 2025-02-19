class Preference < ApplicationRecord
  belongs_to :carrier

  validates :bank_account, presence: true
  validates :avatar, presence: true
  validates :background_mode, presence: true, numericality: { only_integer: true }
end
