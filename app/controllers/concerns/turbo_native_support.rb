module TurboNativeSupport
  extend ActiveSupport::Concern

  included do
    before_action :set_turbo_native_headers
  end

  private

  def turbo_native_app?
    request.user_agent.to_s.match?(/Turbo Native/)
  end

  def turbo_native_ios?
    request.user_agent.to_s.match?(/Turbo Native iOS/)
  end

  def turbo_native_android?
    request.user_agent.to_s.match?(/Turbo Native Android/)
  end

  def set_turbo_native_headers
    if turbo_native_app?
      # Add custom headers for native app detection
      response.headers["X-Turbo-Native"] = "true"

      # Set platform-specific headers
      if turbo_native_ios?
        response.headers["X-Turbo-Platform"] = "ios"
      elsif turbo_native_android?
        response.headers["X-Turbo-Platform"] = "android"
      end
    end
  end

  # Render a native bridge action (for calling native features)
  def turbo_native_action(name, **options)
    render json: {
      action: name,
      options: options
    }, status: :ok
  end

  # Redirect to a recede action (go back in native app)
  def turbo_native_recede
    redirect_to turbo_recede_historical_location_url || root_url
  end
end
