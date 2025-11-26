class Carrier < ApplicationRecord
  # Use a descriptive column name for carrier kind to avoid STI conflicts.
  # The DB migration renames `type` -> `carrier_type` and tests/fixtures must
  # use `carrier_type` going forward.

  has_many :phones
  has_many :documents
  has_many :form_templates
  has_many :tasks
  has_many :carrier_memberships, dependent: :destroy
  has_many :users, through: :carrier_memberships
  has_many :carrier_payouts, dependent: :destroy
  has_one :preference
  has_many :carrier_ratings, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :carrier_type, presence: true
  validates :address, presence: true

  def signature_document
    documents.find_by(id_document: Document::CARRIER_SIGNATURE_ID)
  end

  def signature_present?
    signature_document&.signature.present?
  end

  def recalculate_rating_stats!
    count = carrier_ratings.count
    sender_avg = carrier_ratings.average(:sender_score)&.to_f || 0.0
    recipient_avg = carrier_ratings.average(:recipient_score)&.to_f || 0.0
    completion_avg = carrier_ratings.average(:completion_score)&.to_f || 0.0

    overall_avg = if count.positive?
      average = (sender_avg + recipient_avg + completion_avg) / 3.0
      average.clamp(CarrierRating::MIN_SCORE, CarrierRating::MAX_SCORE).round(2)
    else
      0.0
    end

    update_columns(
      ratings_count: count,
      average_sender_rating: sender_avg.round(2),
      average_service_rating: recipient_avg.round(2),
      average_completion_rating: completion_avg.round(2),
      average_overall_rating: overall_avg,
      updated_at: Time.current
    )
  end

  def rating_summary
    sender_avg = average_sender_rating.to_f
    recipient_avg = average_service_rating.to_f
    completion_avg = average_completion_rating.to_f

    {
      ratings_count: ratings_count,
      average_sender_rating: sender_avg,
      average_recipient_rating: recipient_avg,
      average_service_rating: recipient_avg,
      average_completion_rating: completion_avg,
      average_overall_rating: average_overall_rating.to_f
    }
  end
end
