require "securerandom"

class Task < ApplicationRecord
  include AASM

  MAX_FAILED_ATTEMPTS = 3
  STORAGE_WINDOW = 3.days

  attr_reader :current_failure_note, :current_failure_location

  SNAPSHOT_ATTRIBUTES = %w[
    customer_id carrier_id sender_id messenger_id lawyer_id
    package_type start target failure_code delivery_time status priority
    filled_form_url pickup_address pickup_contact_phone pickup_notes
    requested_pickup_time
  ].freeze

  belongs_to :customer
  belongs_to :carrier
  belongs_to :sender, optional: true  # NEW: Who sends the package
  belongs_to :messenger, optional: true  # NEW: Who delivers the package
  belongs_to :lawyer, optional: true  # NEW: Legal professional for customs/legal tasks

  has_many :payments_tasks
  has_many :payments, through: :payments_tasks
  has_one :cost_calc
  has_many :remarks
  has_many :forms
  has_many :tracking_events, -> { order(occurred_at: :asc) }, dependent: :destroy
  has_many :proof_uploads, dependent: :destroy
  has_one :carrier_payout, dependent: :destroy

  # Define failure_code enum (positional syntax)
  enum :failure_code, { no_failure: 0, address_not_found: 1, recipient_unavailable: 2, package_damaged: 3, refused_delivery: 4 }, prefix: true

  # Define status enum (positional syntax)
  enum :status, { pending: 0, in_transit: 1, delivered: 2, failed: 3, returned: 4 }

  enum :priority, { normal: "normal", urgent: "urgent", express: "express" }, default: :normal

  validates :package_type, presence: true
  validates :start, presence: true
  validates :target, presence: true
  validates :delivery_time, presence: true
  validates :status, presence: true
  validates :barcode, presence: true, uniqueness: true
  validates :filled_form_url, allow_blank: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  # Aliases for notification templates (compatibility)
  alias_attribute :pickup_location, :start
  alias_attribute :drop_off_location, :target

  before_validation :assign_generated_fields, on: :create

  # Generate a display title for the task
  def title
    "#{package_type.titleize} - #{barcode}"
  end

  def snapshot_for_payment
    snapshot = attributes.slice(*SNAPSHOT_ATTRIBUTES)
    snapshot["customer_id"] ||= customer_id
    snapshot["status"] ||= status
    snapshot
  end

  def record_tracking_event!(title:, event_type:, status: nil, description: nil, occurred_at: Time.current, location: nil, metadata: {})
    tracking_events.create!(
      title: title,
      event_type: event_type,
      status: status,
      description: description,
      location: location,
      occurred_at: occurred_at,
      metadata: metadata
    )
  end

  # Optional attributes for notification templates (return nil if not present)

  def scheduled_pickup_time
    nil  # Optional: Scheduled pickup timestamp
  end

  def recipient_name
    nil  # Optional: Name of person who received package
  end

  def signature_image
    nil  # Optional: Signature image URL or data
  end

  def proof_uploaded?
    proof_uploads.exists?
  end

  def failure_code_text
    return nil if failure_code == "no_failure"
    failure_code&.humanize
  end

  # State machine for task workflow
  aasm column: :status, enum: true, whiny_persistence: true do
    state :pending, initial: true
    state :in_transit
    state :delivered
    state :failed
    state :returned

    event :ship do
      transitions from: :pending, to: :in_transit, after: :notify_customer_shipped
    end

    event :deliver do
      transitions from: :in_transit, to: :delivered, after: :notify_customer_delivered
    end

    event :mark_failed do
      transitions from: [ :pending, :in_transit ], to: :failed, after: [ :notify_customer_failed, :handle_failed_attempt ]
    end

    event :return_to_sender do
      transitions from: [ :failed, :in_transit ], to: :returned, after: :notify_customer_returned
    end

    event :retry_delivery do
      transitions from: [ :failed, :returned ], to: :in_transit, after: :notify_customer_retry
    end
  end

  def mark_failed_with_note!(note, failure_code: nil, location: nil)
    self.failure_code = failure_code if failure_code.present?
    @current_failure_note = note
    @current_failure_location = location
    mark_failed!
  ensure
    @current_failure_note = nil
    @current_failure_location = nil
  end

  def begin_retry_after_customer_response!
    update!(awaiting_customer_response: false, stored_until: nil)
    retry_delivery! if may_retry_delivery?
  end

  # Turbo Streams: broadcast task list updates
  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_destroy_commit :broadcast_destroyed

  # Notification callbacks
  after_create_commit :send_task_assigned_notification
  before_update :track_status_change

  private

  def handle_failed_attempt
    note = @current_failure_note.presence || last_failure_note
    location = @current_failure_location
    attempts = failed_attempts.to_i + 1
    storage_deadline = attempts <= MAX_FAILED_ATTEMPTS ? STORAGE_WINDOW.from_now : nil

    update!(
      failed_attempts: attempts,
      last_failure_note: note,
      awaiting_customer_response: attempts <= MAX_FAILED_ATTEMPTS,
      stored_until: storage_deadline
    )

    record_tracking_event!(
      title: "Delivery Attempt Failed",
      event_type: "failed",
      status: "failed",
      description: failure_event_description(note, attempts, storage_deadline),
      metadata: {
        attempt_number: attempts,
        stored_until: storage_deadline&.iso8601,
        location: location&.slice(:lat, :lng, :accuracy)
      }.compact
    )

    handle_post_failure_routing(attempts)
  rescue => e
    Rails.logger.error("[Task #{id}] Failed to process failed attempt: #{e.message}")
  ensure
    @current_failure_note = nil
  end

  def assign_generated_fields
    self.status ||= :pending
    self.delivery_time ||= Time.current
    self.barcode ||= self.class.generate_unique_barcode
  end

  def self.generate_unique_barcode(prefix: "TSK")
    loop do
      code = "#{prefix}#{SecureRandom.hex(5).upcase}"
      break code unless exists?(barcode: code)
    end
  end

  # Track status changes for notifications
  def track_status_change
    @old_status = status_was if status_changed?
  end

  def failure_event_description(note, attempts, storage_deadline)
    parts = []
    parts << note if note.present?
    if attempts <= MAX_FAILED_ATTEMPTS && storage_deadline.present?
      parts << "Parcel stored until #{storage_deadline.strftime('%B %d, %Y %I:%M %p %Z')} awaiting customer response"
    elsif attempts > MAX_FAILED_ATTEMPTS
      parts << "Exceeded #{MAX_FAILED_ATTEMPTS} failed attempts"
    end
    parts << "Attempt #{[attempts, MAX_FAILED_ATTEMPTS].min} of #{MAX_FAILED_ATTEMPTS}" if attempts <= MAX_FAILED_ATTEMPTS
    description = parts.compact.join(" | ")
    description.presence || "Delivery attempt unsuccessful"
  end

  def handle_post_failure_routing(attempts)
    return unless attempts > MAX_FAILED_ATTEMPTS

    update!(awaiting_customer_response: false, stored_until: nil)
    return_to_sender! if may_return_to_sender?
  end

  # Send notification when task is assigned to messenger
  def send_task_assigned_notification
    if messenger.present? && messenger.email.present?
      NotificationService.notify_task_assigned(self)
    end
  rescue => e
    Rails.logger.error("[Task #{id}] Failed to send assignment notification: #{e.message}")
  end

  # State machine callbacks with notifications
  def notify_customer_shipped
    Rails.logger.info("[Task #{id}] Shipped - barcode: #{barcode}")
    NotificationService.notify_status_changed(self, @old_status || "pending")
  rescue => e
    Rails.logger.error("[Task #{id}] Failed to send shipped notification: #{e.message}")
  end

  def notify_customer_delivered
    Rails.logger.info("[Task #{id}] Delivered - barcode: #{barcode}")
    NotificationService.notify_delivery_complete(self)
  rescue => e
    Rails.logger.error("[Task #{id}] Failed to send delivery notification: #{e.message}")
  end

  def notify_customer_failed
    Rails.logger.info("[Task #{id}] Failed - barcode: #{barcode}, reason: #{failure_code}")
    NotificationService.notify_delivery_failed(self)
  rescue => e
    Rails.logger.error("[Task #{id}] Failed to send failure notification: #{e.message}")
  end

  def notify_customer_returned
    Rails.logger.info("[Task #{id}] Returned to sender - barcode: #{barcode}")
    NotificationService.notify_status_changed(self, @old_status || "failed")
  rescue => e
    Rails.logger.error("[Task #{id}] Failed to send return notification: #{e.message}")
  end

  def notify_customer_retry
    Rails.logger.info("[Task #{id}] Retry delivery scheduled - barcode: #{barcode}")
    NotificationService.notify_status_changed(self, @old_status || "failed")
  rescue => e
    Rails.logger.error("[Task #{id}] Failed to send retry notification: #{e.message}")
  end

  # Turbo Streams broadcast methods
  def broadcast_created
    ApplicationController.renderer # ensure renderer is loaded
    broadcast_prepend_later_to "tasks", target: "tasks", partial: "tasks/task", locals: { task: self }
  end

  def broadcast_updated
    broadcast_replace_later_to "tasks", target: ActionView::RecordIdentifier.dom_id(self), partial: "tasks/task", locals: { task: self }
  end

  def broadcast_destroyed
    broadcast_remove_to "tasks", target: ActionView::RecordIdentifier.dom_id(self)
  end
end
