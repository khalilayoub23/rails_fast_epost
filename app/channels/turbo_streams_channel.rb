# Turbo Streams Channel for real-time updates
class TurboStreamsChannel < ApplicationCable::Channel
  # Allowlist of streamable types to prevent Remote Code Execution
  ALLOWED_STREAMABLE_TYPES = %w[
    Delivery Task User Customer Carrier Payment Messenger Sender
  ].freeze

  def subscribed
    # Subscribe to user-specific stream
    stream_for current_user if current_user

    # Subscribe to broadcast streams based on params
    if params[:streamable_type] && params[:streamable_id]
      streamable_type = params[:streamable_type].to_s
      unless ALLOWED_STREAMABLE_TYPES.include?(streamable_type)
        reject
        return
      end
      streamable = streamable_type.constantize.find_by(id: params[:streamable_id])
      return reject unless streamable
      stream_for streamable
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
