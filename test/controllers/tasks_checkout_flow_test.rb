require "test_helper"

class TasksCheckoutFlowTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @carrier = carriers(:one)
    sign_in users(:admin)
  end

  test "creating a task kicks off Stripe checkout" do
    captured = nil
    payment = Payment.new(payment_url: "https://pay.example/checkout", metadata: {})

    Gateways::StripeGateway.stub :create_payment!, ->(**args) {
      captured = args
      payment
    } do
      post tasks_path, params: {
        task: {
          customer_id: @customer.id,
          carrier_id: @carrier.id,
          package_type: "documents",
          start: "Origin",
          target: "Destination",
          delivery_time: 2.days.from_now.iso8601,
          status: :pending
        },
        payment: {
          amount: "120.50",
          currency: "USD",
          service_type: "express_delivery",
          description: "Court filing"
        }
      }
    end

    assert_redirected_to "https://pay.example/checkout"
    assert captured.present?, "expected create_payment! to be invoked"
    assert_nil captured[:task], "task should be nil until payment succeeds"
    snapshot = captured[:metadata]["task_snapshot"]
    assert_equal @customer.id, snapshot["customer_id"]
    assert_equal "Origin", snapshot["start"]
    assert_equal "Destination", snapshot["target"]
    assert_equal "express_delivery", captured[:metadata]["payment_service_type"]
  end

  test "payment success materializes the task" do
    snapshot = {
      "customer_id" => @customer.id,
      "carrier_id" => @carrier.id,
      "package_type" => "legal_docs",
      "start" => "HQ",
      "target" => "Court",
      "status" => Task.statuses[:pending],
      "delivery_time" => 1.day.from_now.iso8601
    }

    payment = Payment.create!(
      provider: "stripe",
      payable: @customer,
      category: :service_fee,
      payment_type: :per_task,
      amount_cents: 5000,
      currency: "USD",
      metadata: {
        "task_snapshot" => snapshot,
        "task_form" => snapshot,
        "payment_form" => { "amount" => "50" },
        "task_cancel_token" => SecureRandom.hex(6)
      },
      gateway_status: :succeeded,
      checkout_session_id: "cs_test_materialize"
    )

    assert_difference -> { Task.count }, 1 do
      get task_payment_success_path, params: { session_id: "cs_test_materialize" }
    end

    task = Task.order(:created_at).last
    assert_redirected_to task_path(task)
    assert_equal payment.reload.task, task
    assert_equal "Court", task.target
  end
end
