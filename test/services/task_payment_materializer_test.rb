require "test_helper"

class TaskPaymentMaterializerTest < ActiveSupport::TestCase
  setup do
    @customer = customers(:one)
    @carrier = carriers(:one)
    @snapshot = {
      "customer_id" => @customer.id,
      "carrier_id" => @carrier.id,
      "package_type" => "Document Delivery",
      "start" => "Tel Aviv",
      "target" => "Haifa",
      "status" => "pending",
      "priority" => "express",
      "pickup_address" => "123 Main",
      "pickup_contact_phone" => "+972-555-0000",
      "delivery_time" => 1.day.from_now.iso8601,
      "task_type" => "delivery_and_pickup",
      "poa_enabled" => false
    }
  end

  test "creates task from snapshot and attaches to payment" do
    payment = Payment.create!(
      provider: "stripe",
      amount_cents: 1500,
      currency: "USD",
      payable: @customer,
      category: :service_fee,
      payment_type: :per_task,
      metadata: { "task_snapshot" => @snapshot }
    )

    task = TaskPaymentMaterializer.new(payment: payment).call

    assert task.persisted?
    assert_equal payment.reload.task, task
    assert_equal @snapshot["package_type"], task.package_type
    assert_equal @snapshot["start"], task.start
    assert_equal @snapshot["target"], task.target
    assert_equal "express", task.priority
  end

  test "raises error when snapshot is missing" do
    payment = Payment.create!(
      provider: "stripe",
      amount_cents: 1500,
      currency: "USD",
      payable: @customer,
      category: :service_fee,
      payment_type: :per_task
    )

    assert_raises(TaskPaymentMaterializer::MissingSnapshotError) do
      TaskPaymentMaterializer.new(payment: payment).call
    end
  end
end
