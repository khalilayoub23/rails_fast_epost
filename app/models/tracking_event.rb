class TrackingEvent < ApplicationRecord
  EVENT_ICONS = {
    "created" => "package",
    "picked_up" => "delivery",
    "in_transit" => "plane",
    "customs" => "warning",
    "at_facility" => "package",
    "out_for_delivery" => "truck",
    "delivered" => "check",
    "failed" => "warning",
    "returned" => "return"
  }.freeze

  belongs_to :task

  validates :event_type, :title, :occurred_at, presence: true

  scope :recent_first, -> { order(occurred_at: :desc) }

  def icon_name
    EVENT_ICONS[event_type] || "truck"
  end

  def description_text
    description.presence || status&.humanize
  end
end
