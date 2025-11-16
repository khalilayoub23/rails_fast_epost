class ContactInquiry < ApplicationRecord
  enum :status, { pending: 0, contacted: 1, resolved: 2 }, default: :pending

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :service, presence: true, inclusion: { in: %w[legal ecommerce other] }

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(status: :pending) }
end
