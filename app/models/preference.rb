class Preference < ApplicationRecord
  belongs_to :carrier

  # Serialize bank_account data
  # Store bank_account as JSON in the text column
  attribute :bank_account, :json, default: {}

  # Define background_mode enum (positional syntax)
  enum :background_mode, { light: 0, dark: 1, auto: 2 }

  validates :bank_account, presence: true
  validates :avatar, presence: true
  validates :background_mode, presence: true
end
