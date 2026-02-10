require "test_helper"
require "securerandom"

class CarrierRatingsTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  def setup_fixtures; end
  def teardown_fixtures; end

  setup do
    @created_carriers = []
    @created_customers = []
    @created_tasks = []
    @created_users = []
    @created_ratings = []

    @user = User.create!(
      email: "api-admin-#{SecureRandom.hex(2)}@example.com",
      password: "password123",
      role: "admin",
      user_type: :sender
    )
    @created_users << @user
    sign_in @user, scope: :user

    @carrier = create_carrier!
    @customer = create_customer!
    @sender = create_sender!
    @task = create_task!(carrier: @carrier, customer: @customer, sender: @sender, status: :delivered)
  end

  teardown do
    CarrierRating.where(id: @created_ratings.map(&:id)).delete_all if @created_ratings.any?
    Task.where(id: @created_tasks.map(&:id)).delete_all if @created_tasks.any?
    Customer.where(id: @created_customers.map(&:id)).delete_all if @created_customers.any?
    Carrier.where(id: @created_carriers.map(&:id)).delete_all if @created_carriers.any?
    User.where(id: @created_users.map(&:id)).delete_all if @created_users.any?
    sign_out @user if @user
  end

  test "creates rating via JSON and updates aggregates" do
    payload = {
      carrier_rating: {
        carrier_id: @carrier.id,
        task_id: @task.id,
        completion_score: 5,
        sender_score: 5,
        recipient_score: 4,
        comment: "Fast and reliable"
      }
    }

    assert_difference("CarrierRating.count", 1) do
      post carrier_ratings_path, params: payload.to_json, headers: json_headers
    end

    assert_response :created

    body = JSON.parse(response.body)
    assert_equal @carrier.id, body["carrier_id"]
    assert_equal 5, body["completion_score"]
    assert_equal 5, body["sender_score"]
    assert_equal 4, body["recipient_score"]
    assert_equal "Fast and reliable", body["comment"]
    assert_in_delta 4.67, body.dig("carrier", "average_overall_rating").to_f, 0.01
    assert_in_delta 5.0, body.dig("carrier", "average_sender_rating").to_f, 0.01
    assert_in_delta 4.0, body.dig("carrier", "average_recipient_rating").to_f, 0.01

    created_rating = CarrierRating.find(body["id"])
    @created_ratings << created_rating

    @carrier.reload
    assert_equal 1, @carrier.ratings_count
    assert_in_delta 5.0, @carrier.average_completion_rating.to_f, 0.01
    assert_in_delta 4.0, @carrier.average_service_rating.to_f, 0.01
    assert_in_delta 5.0, @carrier.average_sender_rating.to_f, 0.01
    assert_in_delta 4.67, @carrier.average_overall_rating.to_f, 0.01
  end

  private

  def json_headers
    {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json"
    }
  end

  def create_user!
    user = User.create!(
      email: "viewer-#{SecureRandom.hex(2)}@example.com",
      password: "password123",
      role: "sender",
      user_type: :sender
    )
    @created_users << user
    user
  end

  def create_carrier!
    carrier = Carrier.create!(
      name: "Carrier #{SecureRandom.hex(2)}",
      email: "carrier-#{SecureRandom.hex(2)}@example.com",
      address: "1 Carrier Plaza",
      carrier_type: "Standard"
    )
    @created_carriers << carrier
    carrier
  end

  def create_customer!
    customer = Customer.create!(
      name: "Customer #{SecureRandom.hex(2)}",
      email: "customer-#{SecureRandom.hex(2)}@example.com",
      address: "100 Customer Way",
      phones: [ "+15550000000" ],
      category: :individual
    )
    @created_customers << customer
    customer
  end

  def create_task!(carrier:, customer:, sender: nil, status: :delivered)
    task = Task.create!(
      customer: customer,
      carrier: carrier,
      sender: sender || @sender,
      task_type: "delivery_and_pickup",
      package_type: "parcel",
      start: "Origin",
      target: "Destination",
      status: status,
      barcode: SecureRandom.hex(6),
      delivery_time: Time.current,
      priority: :normal
    )
    @created_tasks << task
    task
  end

  def create_sender!
    sender = Sender.create!(
      name: "Sender #{SecureRandom.hex(2)}",
      email: "sender-#{SecureRandom.hex(2)}@example.com",
      phone: "+15550001000",
      address: "1 Sender Lane",
      sender_type: :individual
    )
    sender
  end
end
