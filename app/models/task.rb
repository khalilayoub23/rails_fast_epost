require "securerandom"

class Task < ApplicationRecord
  include AASM

  attr_accessor :poa_enabled

  MAX_FAILED_ATTEMPTS = 3
  STORAGE_WINDOW = 3.days

  attr_reader :current_failure_note, :current_failure_location

  SNAPSHOT_ATTRIBUTES = %w[
    customer_id carrier_id sender_id messenger_id lawyer_id
    package_type start target failure_code delivery_time status priority
    filled_form_url pickup_address pickup_contact_phone pickup_notes
    requested_pickup_time case_file_number delivery_medium
    collection_amount collection_currency
    id_number
    archive_item_type archive_quantity archive_duration_days archive_from_date archive_to_date
  ].freeze

  belongs_to :customer, optional: true
  belongs_to :carrier
  belongs_to :sender, optional: true  # NEW: Who sends the package
  belongs_to :messenger, optional: true  # NEW: Who delivers the package
  belongs_to :lawyer, optional: true  # NEW: Legal professional for customs/legal tasks
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :poa_document_template, class_name: "DocumentTemplate", optional: true

  has_many :payments_tasks
  has_many :payments, through: :payments_tasks
  has_one :cost_calc
  has_many :remarks
  has_many :forms
  has_many :tracking_events, -> { order(occurred_at: :asc) }, dependent: :destroy
  has_many :proof_uploads, dependent: :destroy
  has_one :carrier_payout, dependent: :destroy

  # Legal document attachments (PDFs, images, etc.)
  has_many_attached :legal_files
  has_one_attached :power_of_attorney

  COPY_TASK_TYPES = %w[
    criminal_file_photocopying
    traffic_file_photocopying
    document_retrieval_from_government_agencies
  ].freeze

  POWER_OF_ATTORNEY_TASK_TYPES = %w[
    criminal_file_photocopying
    traffic_file_photocopying
    document_retrieval_from_government_agencies
    court_filings
    process_serving
    filing_to_arbitration_mediation_centers
  ].freeze

  POA_MANDATORY_TASK_TYPES = %w[
    court_filings
    process_serving
    document_retrieval_from_government_agencies
  ].freeze

  FILE_UPLOAD_REQUIRED_TYPES = %w[
    court_filings
    process_serving
    notarization_and_apostille
    remote_digital_signature
    criminal_file_photocopying
    traffic_file_photocopying
    enforcement_office_services
    bailiff_services_coordination
    land_registry_tabu_services
    companies_registrar_services
    filing_to_arbitration_mediation_centers
    proof_of_delivery_pod
  ].freeze

  COLLECTION_AMOUNT_TASK_TYPES = %w[
    cash_on_delivery_cod
    payment_collection
  ].freeze

  # Define failure_code enum (positional syntax)
  enum :failure_code, { no_failure: 0, address_not_found: 1, recipient_unavailable: 2, package_damaged: 3, refused_delivery: 4 }, prefix: true

  # Define status enum (positional syntax)
  enum :status, { pending: 0, in_transit: 1, delivered: 2, failed: 3, returned: 4, postponed: 5 }

  enum :priority, { normal: "normal", urgent: "urgent", express: "express" }, default: :normal
  enum :task_type, {
    court_filings: "court_filings",
    process_serving: "process_serving",
    document_retrieval_from_government_agencies: "document_retrieval_from_government_agencies",
    inter_office_courier: "inter_office_courier",
    archive_services: "archive_services",
    notarization_and_apostille: "notarization_and_apostille",
    criminal_file_photocopying: "criminal_file_photocopying",
    traffic_file_photocopying: "traffic_file_photocopying",
    remote_digital_signature: "remote_digital_signature",
    enforcement_office_services: "enforcement_office_services",
    pickup_services: "pickup_services",
    ecommerce_delivery: "ecommerce_delivery",
    ecommerce_pickup: "ecommerce_pickup",
    cash_on_delivery_cod: "cash_on_delivery_cod",
    delivery_and_pickup: "delivery_and_pickup",
    payment_collection: "payment_collection",
    bailiff_services_coordination: "bailiff_services_coordination",
    land_registry_tabu_services: "land_registry_tabu_services",
    companies_registrar_services: "companies_registrar_services",
    filing_to_arbitration_mediation_centers: "filing_to_arbitration_mediation_centers",
    same_day_express_delivery: "same_day_express_delivery",
    warehousing_temporary_storage: "warehousing_temporary_storage",
    proof_of_delivery_pod: "proof_of_delivery_pod"
  }, default: :court_filings

  scope :published, -> { where(published: true) }
  scope :draft, -> { where(published: false) }

  validates :package_type, presence: true
  validates :task_type, presence: true
  validates :start, presence: true, if: :delivery_details_required?
  validates :target, presence: true, if: :delivery_details_required?
  validates :delivery_time, presence: true, if: :delivery_details_required?
  validates :status, presence: true
  validates :barcode, presence: true, uniqueness: true
  validates :case_file_number, presence: true, if: :copy_task_type?
  validates :delivery_medium, presence: true, if: :copy_task_type?
  validates :filled_form_url, allow_blank: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :collection_amount, numericality: { greater_than: 0 }, if: :collection_amount_required?
  validates :collection_currency, presence: true, if: :collection_amount_required?
  validates :id_number, presence: true, if: :remote_digital_signature?
  validates :archive_item_type, presence: true, if: :archive_service?
  validates :archive_from_date, presence: true, if: :archive_service?
  validates :archive_to_date, presence: true, if: :archive_service?
  validates :archive_duration_days, numericality: { only_integer: true, greater_than: 0 }, if: :archive_service?

  # Custom validation for legal file attachments
  validate :validate_legal_files
  validate :power_of_attorney_required
  validate :required_legal_files
  validate :poa_template_has_file
  validate :poa_template_selected
  validate :poa_mandatory_enabled

  # Aliases for notification templates (compatibility)
  alias_attribute :pickup_location, :start
  alias_attribute :drop_off_location, :target

  before_validation :assign_generated_fields, on: :create
  before_validation :calculate_archive_duration_days
  before_validation :attach_poa_from_template
  after_commit :calculate_route_distance, on: :create
  after_commit :mirror_power_of_attorney_to_legal_files
  after_commit :sync_lifecycle_pdf_documents, on: [ :create, :update ]

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

  def draft?
    !published?
  end

  def publish!(timestamp = Time.current, validate: true)
    attrs = { published: true, published_at: timestamp }
    attrs[:status] = :pending if postponed?

    if validate
      update!(attrs)
    else
      attrs[:status] = self.class.statuses[attrs[:status]] if attrs[:status].is_a?(Symbol)
      update_columns(attrs.merge(updated_at: Time.current))
    end
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

  def copy_task_type?
    COPY_TASK_TYPES.include?(task_type)
  end

  def power_of_attorney_required
    return unless POWER_OF_ATTORNEY_TASK_TYPES.include?(task_type)
    return unless poa_enabled?
    return if power_of_attorney.attached?

    errors.add(:power_of_attorney, :blank)
  end

  def mirror_power_of_attorney_to_legal_files
    return unless power_of_attorney.attached?
    return if legal_files.blobs.any? { |blob| blob.id == power_of_attorney.blob_id }

    legal_files.attach(power_of_attorney.blob)
  end

  def attach_poa_from_template
    return unless poa_enabled?
    return if poa_document_template_id.blank?

    template = poa_document_template
    return unless template&.pdf_file&.attached?

    power_of_attorney.attach(template.pdf_file.blob) unless power_of_attorney.attached?
  end

  def poa_template_has_file
    return unless poa_enabled?
    return if poa_document_template_id.blank?
    return if poa_document_template&.pdf_file&.attached?

    errors.add(:poa_document_template_id, :invalid)
  end

  def poa_template_selected
    return unless poa_enabled?
    return unless POWER_OF_ATTORNEY_TASK_TYPES.include?(task_type)
    return if poa_document_template_id.present?

    errors.add(:poa_document_template_id, :blank)
  end

  def poa_mandatory_enabled
    return unless POA_MANDATORY_TASK_TYPES.include?(task_type)
    return if poa_enabled?

    errors.add(:poa_enabled, :blank)
  end

  def required_legal_files
    return unless FILE_UPLOAD_REQUIRED_TYPES.include?(task_type)
    return if legal_files.attached?

    errors.add(:legal_files, :blank)
  end

  def collection_amount_required?
    COLLECTION_AMOUNT_TASK_TYPES.include?(task_type)
  end

  def archive_service?
    task_type == "archive_services"
  end

  def remote_digital_signature?
    task_type == "remote_digital_signature"
  end

  def delivery_details_required?
    !archive_service? && !remote_digital_signature?
  end

  def calculate_archive_duration_days
    return unless archive_service?
    return if archive_from_date.blank? || archive_to_date.blank?

    from_date = archive_from_date.to_date
    to_date = archive_to_date.to_date
    diff_days = (to_date - from_date).to_i + 1
    self.archive_duration_days = diff_days.positive? ? diff_days : nil
  rescue ArgumentError
    self.archive_duration_days = nil
  end

  def poa_enabled?
    ActiveModel::Type::Boolean.new.cast(poa_enabled)
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
    state :postponed
    state :in_transit
    state :delivered
    state :failed
    state :returned

    event :activate do
      transitions from: :postponed, to: :pending
    end

    event :ship do
      transitions from: :pending, to: :in_transit, after: :notify_customer_shipped
    end

    event :deliver do
      transitions from: :in_transit, to: :delivered, after: :notify_customer_delivered
    end

    event :mark_failed do
      transitions from: [ :postponed, :pending, :in_transit ], to: :failed, after: [ :notify_customer_failed, :handle_failed_attempt ]
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

  def validate_legal_files
    return unless legal_files.attached?

    legal_files.each do |file|
      # Validate content type
      unless file.content_type.in?(%w[application/pdf image/png image/jpg image/jpeg])
        errors.add(:legal_files, "#{file.filename} must be a PDF or image file")
      end

      # Validate file size (10MB max)
      if file.byte_size > 10.megabytes
        errors.add(:legal_files, "#{file.filename} must be less than 10MB")
      end
    end
  end

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

  def calculate_route_distance
    return if distance.present?
    return if start.blank? || target.blank?

    km = RouteDistanceService.new(origin: start, destination: target).fetch_distance_km
    update_column(:distance, km) if km.present?
  rescue => e
    Rails.logger.warn("[Task #{id}] Route distance calculation failed: #{e.message}")
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
    parts << "Attempt #{[ attempts, MAX_FAILED_ATTEMPTS ].min} of #{MAX_FAILED_ATTEMPTS}" if attempts <= MAX_FAILED_ATTEMPTS
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

  def sync_lifecycle_pdf_documents
    trigger = if previous_changes.key?("id")
      :created
    elsif previous_changes.key?("status")
      status
    else
      nil
    end

    return if trigger.blank?

    TaskPdfPacketService.call(task: self, trigger: trigger)
  rescue => e
    Rails.logger.error("[Task #{id}] Failed to sync lifecycle PDFs: #{e.message}")
  end
end
