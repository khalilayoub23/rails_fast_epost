class StaticController < ActionController::Base
  # Respond with 204 so browsers stop logging favicon 404 requests
  def favicon
    head :no_content
  end
end
