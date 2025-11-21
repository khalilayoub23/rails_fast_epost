class NotificationPreference < ApplicationRecord
  CHANNELS = {
    email: 0,
    sms: 1,
    in_app: 2
  }.freeze

  belongs_to :notifiable, polymorphic: true

  enum :channel, CHANNELS

  validates :channel, presence: true
  validates :channel, uniqueness: { scope: %i[notifiable_type notifiable_id] }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :quiet_hours_start, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }, allow_nil: true
  validates :quiet_hours_end, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }, allow_nil: true

  scope :enabled, -> { where(enabled: true) }
  scope :for_channel, ->(channel) { where(channel: channel_value(channel)) }

  def self.lookup(notifiable, channel)
    return if notifiable.blank?

    where(notifiable: notifiable, channel: channel_value(channel)).first
  end

  def quiet_hours?
    quiet_hours_start.present? && quiet_hours_end.present?
  end

  def quiet_hours_active?(time = Time.zone.now)
    return false unless quiet_hours?

    current_hour = time.hour

    if quiet_hours_start <= quiet_hours_end
      current_hour >= quiet_hours_start && current_hour < quiet_hours_end
    else
      current_hour >= quiet_hours_start || current_hour < quiet_hours_end
    end
  end

  def self.channel_value(channel)
    channels[channel.to_s]
  end
end
