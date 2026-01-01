# Calculates driving distance between two addresses using Mapbox Directions API
# Requires ENV["MAPBOX_ACCESS_TOKEN"]. Returns distance in kilometers.
require "net/http"
require "json"

class RouteDistanceService
  GOOGLE_DISTANCE_URL = "https://maps.googleapis.com/maps/api/distancematrix/json".freeze

  def initialize(origin:, destination:)
    @origin = origin.to_s
    @destination = destination.to_s
    @api_key = ENV.fetch("GOOGLE_MAPS_API_KEY", nil)
  end

  def fetch_distance_km
    return nil if @origin.blank? || @destination.blank?
    return nil if @api_key.blank?

    uri = URI.parse(GOOGLE_DISTANCE_URL)
    params = {
      origins: @origin,
      destinations: @destination,
      mode: "driving",
      units: "metric",
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body) rescue {}
    element = body.dig("rows", 0, "elements", 0)
    return nil unless element && element["status"] == "OK"

    distance_meters = element.dig("distance", "value")
    return nil unless distance_meters

    (distance_meters.to_f / 1000).round(2)
  rescue => e
    Rails.logger.warn("[RouteDistanceService] failed: #{e.message}")
    nil
  end
end
