class Messenger < ApplicationRecord
  include Notifiable

  # Associations
  belongs_to :carrier, optional: true
  has_many :tasks, dependent: :restrict_with_error

  # Enums
  enum :status, { available: 0, busy: 1, offline: 2 }
  enum :vehicle_type, { van: 0, motorcycle: 1, bicycle: 2, car: 3, truck: 4 }

  # Validations
  validates :name, presence: true
  validates :phone, presence: true
  validates :status, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :employee_id, uniqueness: true, allow_blank: true
  validates :on_time_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Scopes
  scope :available, -> { where(status: :available) }
  scope :busy, -> { where(status: :busy) }
  scope :offline, -> { where(status: :offline) }
  scope :for_carrier, ->(carrier_id) { where(carrier_id: carrier_id) }
  scope :top_performers, -> { where("on_time_rate >= ?", 95).order(on_time_rate: :desc) }
  scope :with_vehicle, -> { where.not(vehicle_type: nil) }

  # Callbacks
  after_initialize :set_defaults, if: :new_record?

  # Methods
  def display_name
    carrier.present? ? "#{name} (#{carrier.name})" : name
  end

  def active_tasks
    tasks.where(status: [ :pending, :in_transit ])
  end

  def active_tasks_count
    active_tasks.count
  end

  def update_location(latitude, longitude)
    update(current_location: {
      lat: latitude,
      lng: longitude,
      updated_at: Time.current
    })
  end

  def calculate_on_time_rate
    return 0.0 if total_deliveries.zero?

    on_time = tasks.where(status: :delivered).where("delivered_at <= expected_delivery_date").count
    ((on_time.to_f / total_deliveries) * 100).round(1)
  end

  def update_performance_metrics
    self.total_deliveries = tasks.where(status: :delivered).count
    self.on_time_rate = calculate_on_time_rate
    save
  end

  def mark_busy!
    update(status: :busy)
  end

  def mark_available!
    update(status: :available) if active_tasks_count.zero?
  end

  def mark_offline!
    update(status: :offline)
  end

  def working_today?
    return true if working_hours.blank?

    day = Date.current.strftime("%A").downcase
    working_hours[day].present?
  end

  private

  def set_defaults
    self.status ||= :offline
    self.total_deliveries ||= 0
    self.on_time_rate ||= 0.0
    self.current_location ||= {}
    self.working_hours ||= {}
  end
end
