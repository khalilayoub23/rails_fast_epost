class FormTemplate < ApplicationRecord
  belongs_to :carrier
  belongs_to :customer
end
