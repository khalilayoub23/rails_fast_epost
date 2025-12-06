class ProofUpload < ApplicationRecord
  belongs_to :task
  belongs_to :carrier
  belongs_to :uploaded_by, class_name: "User"

  has_one_attached :file

  enum :category, {
    photo: "photo",
    signature: "signature",
    id_check: "id_check",
    document: "document",
    other: "other",
    door_affix_photo: "door_affix_photo",
    door_affix_address: "door_affix_address",
    door_affix_extra: "door_affix_extra",
    door_affix_video: "door_affix_video"
  }, default: :photo

  validates :file, presence: true
  validates :recorded_at, presence: true
  validates :category, inclusion: { in: categories.keys }

  before_validation :apply_defaults

  delegate :filename, to: :file, allow_nil: true

  private

  def apply_defaults
    self.recorded_at ||= Time.current
    self.carrier_id ||= task&.carrier_id
  end
end
