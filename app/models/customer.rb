class Customer < ApplicationRecord
    has_many :form_templates
    has_many :forms
    has_many :tasks

    validates :name, presence: true
    validates :phones, presence: true
    validates :category, presence: true, numericality: { only_integer: true }
    validates :address, presence: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  end
  