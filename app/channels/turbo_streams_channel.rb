# Turbo Streams Channel for real-time updates
class TurboStreamsChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to user-specific stream
    stream_for current_user if current_user

    # Subscribe to broadcast streams based on params
    if params[:streamable_type] && params[:streamable_id]
      # Whitelist allowed streamable types to prevent RCE
      allowed_types = %w[Task Payment Notification Delivery]
      if allowed_types.include?(params[:streamable_type])
        streamable = params[:streamable_type].constantize.find(params[:streamable_id])
        stream_for streamable
      end
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
