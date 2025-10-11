class Lawyer < ApplicationRecord
  # Associations
  has_many :tasks, dependent: :nullify
  has_many :customers, through: :tasks

  # Enums
  enum :specialization, {
    customs: 0,
    international_trade: 1,
    contract: 2,
    corporate: 3,
    immigration: 4,
    intellectual_property: 5,
    litigation: 6,
    general_practice: 7
  }, prefix: true

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :license_number, presence: true, uniqueness: true
  validates :specialization, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_specialization, ->(spec) { where(specialization: spec) }

  # Instance methods
  def full_contact
    "#{name} - #{email} - #{phone}"
  end

  def display_name
    "#{name} (#{specialization.titleize})"
  end

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  def add_certification(cert_name, cert_date, issuer = nil)
    certs = certifications || {}
    certs[cert_name] = {
      date: cert_date,
      issuer: issuer,
      added_at: Time.current
    }
    update!(certifications: certs)
  end

  def certification_list
    return [] if certifications.blank?
    certifications.keys
  end
end
