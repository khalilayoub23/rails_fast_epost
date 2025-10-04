class Customer < ApplicationRecord
    has_many :form_templates
    has_many :forms
    has_many :tasks

    # Store phones as JSON in the text column and default to an empty array
    attribute :phones, :json, default: []

    # Define category enum (positional syntax for ActiveRecord 8)
    enum :category, { individual: 0, business: 1, government: 2 }

    validates :name, presence: true
    validates :phones, presence: true
    validates :category, presence: true
    validates :address, presence: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
