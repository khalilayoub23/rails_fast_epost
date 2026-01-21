require "test_helper"
require "securerandom"

class Api::V1::CarriersSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @carrier = Carrier.create!(
      name: "API Carrier #{SecureRandom.hex(2)}",
      email: "carrier-api-#{SecureRandom.hex(2)}@example.com",
      address: "#{SecureRandom.hex(2)} JSON Plaza",
      carrier_type: "Express"
    )

    customer = Customer.create!(
      name: "JSON Customer #{SecureRandom.hex(2)}",
      email: "customer-api-#{SecureRandom.hex(2)}@example.com",
      address: "100 Api Ave",
      phones: [ "+15550001111" ],
      category: :business
    )

    task = Task.create!(
      customer: customer,
      carrier: @carrier,
      package_type: "parcel",
      start: "Origin",
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
      sender_score: 4,
      recipient_score: 3,
      rated_by: "api@example.com"
    )

    @carrier.reload
  end

  test "index exposes stable rating payload" do
    get api_v1_carriers_path, as: :json
    assert_response :success

    payload = JSON.parse(response.body)
    assert_kind_of Array, payload

    carrier_json = payload.find { |row| row["id"] == @carrier.id }
    assert_not_nil carrier_json
    assert_equal @carrier.name, carrier_json["name"]

    %w[
      average_overall_rating
      average_sender_rating
      average_service_rating
      average_completion_rating
      ratings_count
    ].each do |metric|
      assert carrier_json.key?(metric), "missing #{metric} field"
    end

    assert_in_delta @carrier.average_overall_rating.to_f, carrier_json["average_overall_rating"].to_f, 0.01
    assert_equal @carrier.ratings_count, carrier_json["ratings_count"]
  end

  test "show endpoint returns carrier schema with rating metrics" do
    get api_v1_carrier_path(@carrier), as: :json
    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal @carrier.id, payload["id"]
    assert_equal @carrier.email, payload["email"]
    assert_in_delta @carrier.average_sender_rating.to_f, payload["average_sender_rating"].to_f, 0.01
    assert_in_delta @carrier.average_overall_rating.to_f, payload["average_overall_rating"].to_f, 0.01
  end

  test "create endpoint validates presence of required fields" do
    post api_v1_carriers_path,
         params: { carrier: { email: "missing-name@example.com" } },
         as: :json

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_includes payload["errors"].join(" "), "Name"
    assert_includes payload["errors"].join(" "), "Carrier type"
  end
end
