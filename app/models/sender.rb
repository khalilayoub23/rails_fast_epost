class Sender < ApplicationRecord
  include Notifiable

  # Associations
  has_many :tasks, dependent: :restrict_with_error

  # Enums
  enum :sender_type, { individual: 0, business: 1, government: 2 }

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :address, presence: true
  validates :sender_type, presence: true

  # Business validations (only for business/government types)
  validates :company_name, presence: true, if: -> { business? || government? }
  validates :tax_id, presence: true, if: :business?

  # Scopes
  scope :individuals, -> { where(sender_type: :individual) }
  scope :businesses, -> { where(sender_type: :business) }
  scope :governments, -> { where(sender_type: :government) }
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { joins(:tasks).where(tasks: { created_at: 3.months.ago.. }).distinct }

  # Methods
  def display_name
    sender_type == "individual" ? name : company_name || name
  end

  def full_contact_info
    info = [ name, email, phone ]
    info << company_name if company_name.present?
    info.join(" | ")
  end

  def total_shipments
    tasks.count
  end

  def recent_shipments(limit = 5)
    tasks.order(created_at: :desc).limit(limit)
  end
end
