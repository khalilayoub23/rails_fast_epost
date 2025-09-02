class Phone < ApplicationRecord
  belongs_to :carrier

  validates :number, presence: true
  validates :primary, inclusion: { in: [true, false] }
end
