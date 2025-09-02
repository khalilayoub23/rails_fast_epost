class Preference < ApplicationRecord
  belongs_to :carrier

  # Serialize bank_account data
  serialize :bank_account, Hash

  # Define background_mode enum
  enum background_mode: {
    light: 0,
    dark: 1,
    auto: 2
  }

  validates :bank_account, presence: true
  validates :avatar, presence: true
  validates :background_mode, presence: true
end
