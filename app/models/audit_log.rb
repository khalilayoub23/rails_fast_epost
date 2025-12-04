class AuditLog < ApplicationRecord
  belongs_to :delivery
  belongs_to :user, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
