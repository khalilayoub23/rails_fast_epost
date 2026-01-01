require "test_helper"

class RouteDistanceServiceTest < ActiveSupport::TestCase
  def test_fetch_distance_between_herzl_addresses
    skip "GOOGLE_MAPS_API_KEY not set" unless ENV["GOOGLE_MAPS_API_KEY"].present?

    distance_km = RouteDistanceService.new(
      origin: "הרצל 55 עכו",
      destination: "הרצל 16 חיפה"
    ).fetch_distance_km

    assert distance_km.present?, "Expected a distance in kilometers from Google Distance Matrix"
    assert distance_km.positive?, "Distance should be positive"

    puts "Google Distance Matrix returned #{distance_km} km between הרצל 55 עכו and הרצל 16 חיפה"
  end

  def test_cost_calculation_for_herzl_route
    skip "GOOGLE_MAPS_API_KEY not set" unless ENV["GOOGLE_MAPS_API_KEY"].present?

    distance_km = RouteDistanceService.new(
      origin: "הרצל 55 עכו",
      destination: "הרצל 16 חיפה"
    ).fetch_distance_km

    assert distance_km.present?, "Expected a distance in kilometers from Google Distance Matrix"
    assert distance_km.positive?, "Distance should be positive"

    task = Task.new(distance: distance_km, priority: "normal")
    calculator = CostCalculator.new(task)

    total_cost = calculator.total_cost
    cost_details = calculator.cost_details

    assert total_cost.positive?, "Total cost should be positive"
    assert cost_details.present?, "Cost details should be present"

    puts "Total cost for #{distance_km} km: #{format('%.2f', total_cost)} ILS"
    puts "Cost breakdown (ILS):"
    cost_details.each do |label, value|
      puts "  #{label}: #{value.inspect}"
    end
  end
end
