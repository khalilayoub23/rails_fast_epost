class Customer < ApplicationRecord
    has_many :form_templates
    has_many :forms
    has_many :tasks

    # Serialize phones array
    serialize :phones, Array

    # Define category enum
    enum category: {
        individual: 0,
        business: 1,
        government: 2
    }

    validates :name, presence: true
    validates :phones, presence: true
    validates :category, presence: true
    validates :address, presence: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
  