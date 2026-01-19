require "test_helper"
require "securerandom"

class CarrierRatingTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup_fixtures; end
  def teardown_fixtures; end

  setup do
    @created_carriers = []
    @created_customers = []
    @created_tasks = []
    @created_ratings = []
    @carrier = create_carrier!
    @other_carrier = create_carrier!
    @customer = create_customer!
    @delivered_task = create_task!(@carrier, @customer, status: :delivered)
    @in_transit_task = create_task!(@carrier, @customer, status: :in_transit)
  end

  teardown do
    CarrierRating.where(id: @created_ratings.map(&:id)).delete_all
    Task.where(id: @created_tasks.map(&:id)).delete_all
    Customer.where(id: @created_customers.map(&:id)).delete_all
    Carrier.where(id: @created_carriers.map(&:id)).delete_all
  end

  test "valid rating updates carrier aggregates" do
    rating = track_rating(CarrierRating.create!(
      carrier: @carrier,
      task: @delivered_task,
      completion_score: 5,
      sender_score: 5,
      recipient_score: 4,
      rated_by: "qa@example.com"
    ))

    @carrier.reload
    assert_equal 1, @carrier.ratings_count
    assert_in_delta 5.0, @carrier.average_completion_rating.to_f, 0.01
    assert_in_delta 4.0, @carrier.average_service_rating.to_f, 0.01
    assert_in_delta 5.0, @carrier.average_sender_rating.to_f, 0.01
    assert_in_delta 4.67, @carrier.average_overall_rating.to_f, 0.01
    assert_equal rating.id, CarrierRating.recent_first.first.id
  end

  test "task must belong to carrier" do
    rating = CarrierRating.new(
      carrier: @other_carrier,
      task: @delivered_task,
      completion_score: 3,
      sender_score: 3,
      recipient_score: 3
    )

    assert_not rating.valid?
    assert_includes rating.errors[:task_id], "does not belong to selected carrier"
  end

  test "task must be delivered" do
    rating = CarrierRating.new(
      carrier: @carrier,
      task: @in_transit_task,
      completion_score: 4,
      sender_score: 4,
      recipient_score: 4
    )

    assert_not rating.valid?
    assert_includes rating.errors[:task_id], "must reference a delivered task"
  end

  private

  def reset_rating_data!
    CarrierRating.delete_all
    Task.delete_all
    Carrier.delete_all
    Customer.delete_all
  end

  def create_carrier!(email = "carrier-#{SecureRandom.hex(4)}@example.com")
    carrier = Carrier.create!(
      name: "Carrier #{SecureRandom.hex(2)}",
      email: email,
      address: "1 Carrier Plaza",
      carrier_type: "Standard"
    )
    @created_carriers << carrier
    carrier
  end

  def create_customer!(email = "customer-#{SecureRandom.hex(4)}@example.com")
    customer = Customer.create!(
      name: "Customer #{SecureRandom.hex(2)}",
      email: email,
      address: "100 Customer Way",
      phones: [ "+15550000000" ],
      category: :individual
    )
    @created_customers << customer
    customer
  end

  def create_task!(carrier, customer, status: :delivered)
    task = Task.create!(
      customer: customer,
      carrier: carrier,
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

  def track_rating(rating)
    @created_ratings << rating
    rating
  end
end
