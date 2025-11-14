class Task < ApplicationRecord
  include AASM

  belongs_to :customer
  belongs_to :carrier
  belongs_to :sender, optional: true  # NEW: Who sends the package
  belongs_to :messenger, optional: true  # NEW: Who delivers the package
  belongs_to :lawyer, optional: true  # NEW: Legal professional for customs/legal tasks

  has_many :payments_tasks
  has_many :payments, through: :payments_tasks
  has_one :cost_calc
  has_many :remarks

  # Define failure_code enum (positional syntax)
  enum :failure_code, { no_failure: 0, address_not_found: 1, recipient_unavailable: 2, package_damaged: 3, refused_delivery: 4 }, prefix: true

  # Define status enum (positional syntax)
  enum :status, { pending: 0, in_transit: 1, delivered: 2, failed: 3, returned: 4 }

  validates :package_type, presence: true
  validates :start, presence: true
  validates :target, presence: true
  validates :delivery_time, presence: true
  validates :status, presence: true
  validates :barcode, presence: true, uniqueness: true
  validates :filled_form_url, allow_nil: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  # Aliases for notification templates (compatibility)
  alias_attribute :pickup_location, :start
  alias_attribute :drop_off_location, :target

  # Generate a display title for the task
  def title
    "#{package_type.titleize} - #{barcode}"
  end

  # Optional attributes for notification templates (return nil if not present)
  def priority
    nil  # Optional: Can be 'normal', 'urgent', 'express'
  end

  def scheduled_pickup_time
    nil  # Optional: Scheduled pickup timestamp
  end

  def recipient_name
    nil  # Optional: Name of person who received package
  end

  def signature_image
    nil  # Optional: Signature image URL or data
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
      transitions from: [ :pending, :in_transit ], to: :failed, after: :notify_customer_failed
    end

    event :return_to_sender do
      transitions from: [ :failed, :in_transit ], to: :returned, after: :notify_customer_returned
    end

    event :retry_delivery do
      transitions from: [ :failed, :returned ], to: :in_transit, after: :notify_customer_retry
    end
  end

  # Turbo Streams: broadcast task list updates
  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_destroy_commit :broadcast_destroyed

  # Notification callbacks
  after_create_commit :send_task_assigned_notification
  before_update :track_status_change

  private

  # Track status changes for notifications
  def track_status_change
    @old_status = status_was if status_changed?
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
