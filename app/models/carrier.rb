class Carrier < ApplicationRecord
    has_many :phones
    has_many :documents
    has_many :form_templates
    has_many :tasks
    has_one :preference

    validates :name, presence: true, uniqueness: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :type, presence: true
    validates :address, presence: true
end
  