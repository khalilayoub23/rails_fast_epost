class Customer < ApplicationRecord
    has_many :form_templates
    has_many :forms
    has_many :tasks
  end
  