class Phone < ApplicationRecord
  belongs_to :carrier

  validates :primary, inclusion: { in: [true, false] }

end
