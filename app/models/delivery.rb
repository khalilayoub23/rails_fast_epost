require "securerandom"

class Delivery < ApplicationRecord
  SIGNATURE_ROLES = %w[sender courier recipient].freeze

  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :courier, class_name: "User"

  has_many :signature_events, dependent: :restrict_with_error
  has_many :audit_logs, dependent: :destroy

  has_one_attached :original_court_pdf
  has_one_attached :base_pdf
  has_one_attached :current_pdf
  has_one_attached :final_pdf
  has_one_attached :sender_signature_copy
  has_one_attached :courier_signature_copy
  has_one_attached :recipient_signature_copy

  enum :status, {
    draft: 0,
    awaiting_signatures: 1,
    partially_signed: 2,
    fully_signed: 3,
    completed: 4
  }

  before_validation :assign_case_number, on: :create
  before_validation :normalize_case_number
  before_create :initialize_signature_data

  validates :case_number, presence: true, uniqueness: { message: "has already been taken. Please leave blank to auto-generate or choose a unique number." }
  validates :sender, :recipient, :courier, presence: true
  validate :participants_are_distinct
  validate :courier_has_signature
  validate :lawyer_sender_has_signature

  def signature_required?(role)
    signature_data.dig(role.to_s, "required") || false
  end

  def signature_completed?(role)
    signature_data.dig(role.to_s, "signed") || false
  end

  def all_required_signatures_completed?
    SIGNATURE_ROLES.all? { |role| signature_completed?(role) }
  end

  def pending_signatures
    SIGNATURE_ROLES.reject { |role| signature_completed?(role) }
  end

  def signature_timeline
    SIGNATURE_ROLES.filter_map do |role|
      data = signature_data[role]
      next unless data.present? && data["signed"]

      data.merge("role" => role)
    end.sort_by { |entry| entry["signed_at"].to_s }
  end

  def signature_snapshot
    signature_data.deep_dup
  end

  def signature_data
    value = self[:signature_data]
    value.is_a?(Hash) ? value.deep_stringify_keys : {}
  end

  def signature_details_for(role)
    signature_snapshot[role.to_s] || {}
  end

  def signature_progress
    total = SIGNATURE_ROLES.count { |role| signature_required?(role) }
    completed = SIGNATURE_ROLES.count { |role| signature_completed?(role) }
    percentage = total.zero? ? 0 : ((completed.to_f / total) * 100).round(2)

    {
      completed: completed,
      total: total,
      percentage: percentage
    }
  end

  def verify_signature_integrity(role)
    data = signature_data[role.to_s]
    return false if data.blank?

    expected_hash = data["signature_hash"]
    latest_event = signature_events.signature_added.where(role: role).order(created_at: :desc).first
    latest_event&.signature_hash == expected_hash
  end

  def barcode_data
    return nil unless id.present? && case_number.present?

    "DEL-#{id}-#{case_number}"
  end

  private

  def assign_case_number
    return if case_number.present?

    self.case_number = generate_case_number
  end

  def normalize_case_number
    self.case_number = case_number&.strip&.upcase
  end

  def signature_data=(value)
    normalized = value.respond_to?(:deep_stringify_keys) ? value.deep_stringify_keys : {}
    self[:signature_data] = normalized
  end

  def initialize_signature_data
    current = signature_data

    SIGNATURE_ROLES.each do |role|
      current[role] ||= {
        "required" => true,
        "signed" => false
      }
    end

    self.signature_data = current
  end

  def participants_are_distinct
    participants = [ sender_id, recipient_id, courier_id ].compact
    return if participants.size == 3 && participants.uniq.size == 3

    errors.add(:base, "Sender, courier, and recipient must be different users")
  end

  def courier_has_signature
    return unless require_saved_signatures?
    return if courier.blank?
    return unless courier.user_type_courier?
    return if courier.has_saved_signature?

    errors.add(:courier, "must have a saved signature before delivery can be created")
  end

  def lawyer_sender_has_signature
    return unless require_saved_signatures?
    return if sender.blank?
    return unless sender.user_type_lawyer?
    return if sender.has_saved_signature?

    errors.add(:sender, "lawyers must have a saved signature on file")
  end

  def generate_case_number
    loop do
      token = SecureRandom.alphanumeric(6).upcase
      candidate = "CASE-#{Time.current.year}-#{token}"
      break candidate unless Delivery.exists?(case_number: candidate)
    end
  end

  def require_saved_signatures?
    deliveries_config = Rails.configuration.x.try(:deliveries)
    value = deliveries_config&.require_saved_signatures
    return Rails.env.production? if value.nil?

    value
  end
end
