require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "should create payment with valid attributes" do
    payment = Payment.new(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      amount_cents: 5000,
      currency: "USD",
      provider: "stripe"
    )
    assert payment.valid?
  end

  test "should validate presence of required fields" do
    payment = Payment.new
    assert_not payment.valid?
    assert_includes payment.errors[:category], "can't be blank"
    assert_includes payment.errors[:payment_type], "can't be blank"
  end

  test "should validate amount_cents is positive integer" do
    payment = Payment.new(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      amount_cents: -100,
      currency: "USD"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "must be greater than 0"
  end

  test "should validate external_id uniqueness scoped to provider" do
    Payment.create!(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      external_id: "stripe_12345",
      provider: "stripe",
      amount_cents: 1000,
      currency: "USD"
    )

    duplicate = Payment.new(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      external_id: "stripe_12345",
      provider: "stripe",
      amount_cents: 2000,
      currency: "USD"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_id], "has already been taken"
  end

  test "should belong to task" do
    payment = payments(:one)
    assert_respond_to payment, :task
  end

  test "should belong to polymorphic payable" do
    payment = payments(:one)
    assert_respond_to payment, :payable
  end

  test "should have many tasks through payments_tasks" do
    payment = payments(:one)
    assert_respond_to payment, :tasks
    assert_respond_to payment, :payments_tasks
  end

  test "should have many refunds" do
    payment = payments(:one)
    assert_respond_to payment, :refunds
  end

  test "should have category enum" do
    payment = Payment.create!(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      amount_cents: 1000,
      currency: "USD"
    )

    assert payment.service_fee?
    payment.category = :delivery_fee
    assert payment.delivery_fee?
  end

  test "should have payment_type enum" do
    payment = Payment.create!(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      amount_cents: 1000,
      currency: "USD"
    )

    assert payment.per_task?
    payment.payment_type = :lump_sum
    assert payment.lump_sum?
  end

  test "should have gateway_status enum with prefix" do
    payment = Payment.create!(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      gateway_status: :created,
      amount_cents: 1000,
      currency: "USD"
    )

    assert payment.gateway_status_created?
    payment.gateway_status = :pending
    assert payment.gateway_status_pending?
  end

  test "mark_succeeded! should update gateway_status" do
    payment = Payment.create!(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      gateway_status: :pending,
      amount_cents: 1000,
      currency: "USD"
    )

    payment.mark_succeeded!
    assert payment.gateway_status_succeeded?
  end

  test "mark_failed! should update gateway_status" do
    payment = Payment.create!(
      task: tasks(:one),
      payable: customers(:one),
      category: :service_fee,
      payment_type: :per_task,
      gateway_status: :pending,
      amount_cents: 1000,
      currency: "USD"
    )

    payment.mark_failed!
    assert payment.gateway_status_failed?
  end
end
