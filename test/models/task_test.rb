require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "should create task with valid attributes" do
    task = Task.new(
      customer: customers(:one),
      carrier: carriers(:one),
      package_type: "box",
      start: "Location A",
      target: "Location B",
      delivery_time: 2.days.from_now,
      status: :pending,
      barcode: "TEST123456"
    )
    assert task.valid?
  end

  test "should validate presence of required fields" do
    task = Task.new
    assert_not task.valid?
    assert_includes task.errors[:package_type], "can't be blank"
    assert_includes task.errors[:start], "can't be blank"
    assert_includes task.errors[:target], "can't be blank"
    assert_includes task.errors[:delivery_time], "can't be blank"
    assert_includes task.errors[:status], "can't be blank"
    assert_includes task.errors[:barcode], "can't be blank"
  end

  test "should validate uniqueness of barcode" do
    task1 = Task.create!(
      customer: customers(:one),
      carrier: carriers(:one),
      package_type: "box",
      start: "A",
      target: "B",
      delivery_time: 1.day.from_now,
      status: :pending,
      barcode: "UNIQUE123"
    )

    task2 = Task.new(
      customer: customers(:one),
      carrier: carriers(:one),
      package_type: "box",
      start: "C",
      target: "D",
      delivery_time: 2.days.from_now,
      status: :pending,
      barcode: "UNIQUE123"
    )

    assert_not task2.valid?
    assert_includes task2.errors[:barcode], "has already been taken"
  end

  test "should belong to customer" do
    task = tasks(:one)
    assert_respond_to task, :customer
  end

  test "should belong to carrier" do
    task = tasks(:one)
    assert_respond_to task, :carrier
  end

  test "should have many payments through payments_tasks" do
    task = tasks(:one)
    assert_respond_to task, :payments
    assert_respond_to task, :payments_tasks
  end

  test "should have one cost_calc" do
    task = tasks(:one)
    assert_respond_to task, :cost_calc
  end

  test "should have many remarks" do
    task = tasks(:one)
    assert_respond_to task, :remarks
  end

  test "should have status enum" do
    task = Task.create!(
      customer: customers(:one),
      carrier: carriers(:one),
      package_type: "box",
      start: "A",
      target: "B",
      delivery_time: 1.day.from_now,
      status: :pending,
      barcode: "STATUS123"
    )

    assert task.pending?
    task.status = :in_transit
    assert task.in_transit?
    task.status = :delivered
    assert task.delivered?
  end

  test "should have failure_code enum with prefix" do
    task = Task.create!(
      customer: customers(:one),
      carrier: carriers(:one),
      package_type: "box",
      start: "A",
      target: "B",
      delivery_time: 1.day.from_now,
      status: :pending,
      barcode: "FAILURE123",
      failure_code: :no_failure
    )

    assert task.failure_code_no_failure?
    task.failure_code = :address_not_found
    assert task.failure_code_address_not_found?
  end
end
