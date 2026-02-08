class Customer < ApplicationRecord
  include Notifiable

  attr_accessor :allow_partial_profile
  attr_accessor :first_name, :last_name

  has_many :form_templates
  has_many :forms
  has_many :tasks

  # Store phones as JSON in the text column and default to an empty array
  attribute :phones, :json, default: []

  # Define category enum (positional syntax for ActiveRecord 8)
  enum :category, { individual: 0, business: 1, government: 2 }

  validates :name, presence: true

  before_validation :compose_name_from_parts

  with_options unless: :allow_partial_profile? do
    validates :phones, presence: true
    validates :category, presence: true
    validates :address, presence: true
    validates :email, presence: true
  end

  validates :email, uniqueness: true, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true

  # Alias for email templates
  def full_name
    name
  end

  def first_name
    return @first_name if @first_name.present?
    name.to_s.split.first.to_s
  end

  def last_name
    return @last_name if @last_name.present?
    parts = name.to_s.split
    parts.length > 1 ? parts[1..].join(" ") : ""
  end

  # Return first phone number for email templates
  def phone
    phones&.first || "N/A"
  end

  def allow_partial_profile?
    !!@allow_partial_profile
  end

  private

  def compose_name_from_parts
    parts = [@first_name, @last_name].map { |part| part.to_s.strip }.reject(&:empty?)
    return if parts.empty?

    self.name = parts.join(" ")
  end
end
