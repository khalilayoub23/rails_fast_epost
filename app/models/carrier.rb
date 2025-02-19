class Carrier < ApplicationRecord
    has_many :phones
    has_many :documents
    has_many :form_templates
    has_many :tasks
    has_one :preference
end
  