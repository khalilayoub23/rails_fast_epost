class NotificationLog < ApplicationRecord
  CHANNELS = NotificationPreference::CHANNELS
  STATUSES = {
    sent: "sent",
    skipped: "skipped",
    failed: "failed"
  }.freeze

  belongs_to :notifiable, polymorphic: true, optional: true

  enum :channel, CHANNELS

  validates :channel, presence: true
  validates :message_type, presence: true
  validates :status, inclusion: { in: STATUSES.values }

  def self.record!(message_type:, channel:, status:, notifiable: nil, metadata: {}, provider_message_id: nil)
    create!(
      message_type: message_type,
      channel: channel,
      status: status,
      notifiable: notifiable,
      metadata: metadata,
      provider_message_id: provider_message_id,
      sent_at: status == STATUSES[:sent] ? Time.current : nil
    )
  end
end
