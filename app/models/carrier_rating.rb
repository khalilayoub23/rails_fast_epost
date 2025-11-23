class CarrierRating < ApplicationRecord
  MIN_SCORE = 1
  MAX_SCORE = 5

  belongs_to :carrier
  belongs_to :task

  validates :completion_score, presence: true, inclusion: { in: MIN_SCORE..MAX_SCORE }
  validates :sender_score, presence: true, inclusion: { in: MIN_SCORE..MAX_SCORE }
  validates :recipient_score, presence: true, inclusion: { in: MIN_SCORE..MAX_SCORE }
  validates :task_id, uniqueness: true
  validate :task_belongs_to_carrier
  validate :task_must_be_delivered

  before_validation :populate_defaults
  after_save :refresh_carrier_rollup
  after_destroy :refresh_carrier_rollup

  scope :recent_first, -> { order(created_at: :desc) }

  private

  def populate_defaults
    self.rated_by ||= Current.user&.email
  end

  def task_belongs_to_carrier
    return if task.blank? || carrier.blank?
    return if task.carrier_id == carrier_id

    errors.add(:task_id, :invalid, message: "does not belong to selected carrier")
  end

  def task_must_be_delivered
    return if task.blank?
    return if task.status == "delivered"

    errors.add(:task_id, :invalid, message: "must reference a delivered task")
  end

  def refresh_carrier_rollup
    carrier&.recalculate_rating_stats!
  end
end
