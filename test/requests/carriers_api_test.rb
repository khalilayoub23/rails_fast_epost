require "test_helper"
require "securerandom"

class CarriersApiTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @carrier = Carrier.create!(
      name: "JSON Carrier",
      email: "json-carrier@example.com",
      address: "400 Api Lane",
      carrier_type: "Express"
    )

    customer = Customer.create!(
      name: "JSON Customer",
      email: "json-customer@example.com",
      address: "401 Api Lane",
      phones: [ "+15558889999" ],
      category: :business
    )

    task = Task.create!(
      customer: customer,
      carrier: @carrier,
      task_type: "delivery_and_pickup",
      package_type: "parcel",
      start: "Warehouse",
      target: "Destination",
      status: :delivered,
      barcode: "API#{SecureRandom.hex(3)}",
      delivery_time: Time.current,
      priority: :normal
    )

    CarrierRating.create!(
      carrier: @carrier,
      task: task,
      completion_score: 5,
      sender_score: 5,
      recipient_score: 4,
      rated_by: "api@example.com"
    )

    @carrier.reload
  end

  test "carriers index returns rating aggregates in JSON" do
    sign_in @admin

    get carriers_path(format: :json)
    assert_response :success

    payload = JSON.parse(response.body)
    carrier_json = payload.find { |row| row["id"] == @carrier.id }
    assert_not_nil carrier_json
    assert_in_delta 5.0, carrier_json["average_completion_rating"].to_f, 0.01
    assert_in_delta 4.67, carrier_json["average_overall_rating"].to_f, 0.01
  end

  test "carrier show returns rating aggregates in JSON" do
    sign_in @admin

    get carrier_path(@carrier, format: :json)
    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal @carrier.id, payload["id"]
    assert_in_delta 4.67, payload["average_overall_rating"].to_f, 0.01
  end
end
