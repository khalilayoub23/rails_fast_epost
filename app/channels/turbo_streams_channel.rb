# Turbo Streams Channel for real-time updates
class TurboStreamsChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to user-specific stream
    stream_for current_user if current_user

    # Subscribe to broadcast streams based on params
    if params[:streamable_type] && params[:streamable_id]
      streamable = params[:streamable_type].constantize.find(params[:streamable_id])
      stream_for streamable
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
