class CarrierRatingsController < ApplicationController
  def create
    @carrier_rating = CarrierRating.new(carrier_rating_params)
    @carrier_rating.rated_by ||= current_user&.email

    if @carrier_rating.save
      respond_to do |format|
        format.html { redirect_back fallback_location: dashboard_path, notice: t("carrier_ratings.created", default: "Rating recorded.") }
        format.json { render json: rating_payload(@carrier_rating), status: :created }
      end
    else
      respond_to do |format|
        format.html do
          redirect_back fallback_location: dashboard_path,
                        alert: @carrier_rating.errors.full_messages.to_sentence
        end
        format.json { render json: { errors: @carrier_rating.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def carrier_rating_params
    params.require(:carrier_rating).permit(:carrier_id, :task_id, :completion_score, :sender_score, :recipient_score, :comment)
  end

  def rating_payload(rating)
    {
      id: rating.id,
      carrier_id: rating.carrier_id,
      task_id: rating.task_id,
      completion_score: rating.completion_score,
      sender_score: rating.sender_score,
      recipient_score: rating.recipient_score,
      rated_by: rating.rated_by,
      comment: rating.comment,
      carrier: rating.carrier.rating_summary
    }
  end
end
