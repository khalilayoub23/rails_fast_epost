require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier
  setup do
    @user = users(:admin)
    sign_in @user
    @customer = customers(:one)
    @carrier = carriers(:one)
  end

  test "POST /tasks redirects to Stripe checkout and stores snapshot" do
    payment = Payment.create!(
      provider: "stripe",
      amount_cents: 1500,
      currency: "USD",
      payable: @customer,
      category: :service_fee,
      payment_type: :per_task,
      payment_url: "https://stripe.test/checkout"
    )

    captured_metadata = nil

    Gateways::StripeGateway.stub :create_payment!, ->(amount_cents:, currency:, task:, payable:, metadata:) do
      captured_metadata = metadata
      payment.update!(metadata: metadata)
      payment
    end do
      assert_no_changes -> { Task.count } do
        post tasks_path, params: {
          task: {
            customer_id: @customer.id,
            carrier_id: @carrier.id,
            package_type: "Legal Docs",
            start: "Jerusalem",
            target: "Haifa",
            priority: "urgent"
          },
          payment: {
            amount: "150",
            currency: "USD",
            service_type: "standard_delivery",
            description: "Priority"
          }
        }
      end
    end

    assert_redirected_to payment.payment_url
    assert captured_metadata.present?, "metadata should be captured"
    assert_equal "Legal Docs", captured_metadata.dig("task_snapshot", "package_type")
    assert_equal "urgent", captured_metadata.dig("task_snapshot", "priority")
    assert_equal "standard_delivery", captured_metadata["payment_service_type"]
    assert_match "tasks/payment/success", captured_metadata["success_url"]
  end

  test "GET /tasks/payment/success persists task when payment succeeded" do
    snapshot = {
      "customer_id" => @customer.id,
      "carrier_id" => @carrier.id,
      "package_type" => "Secure Delivery",
      "start" => "Tel Aviv",
      "target" => "Beer Sheva"
    }

    payment = Payment.create!(
      provider: "stripe",
      amount_cents: 3200,
      currency: "USD",
      payable: @customer,
      category: :service_fee,
      payment_type: :per_task,
      metadata: { "task_snapshot" => snapshot },
      checkout_session_id: "cs_test_123",
      gateway_status: "succeeded"
    )

    assert_difference("Task.count", 1) do
      get task_payment_success_path, params: { session_id: payment.checkout_session_id }
    end

    task = Task.order(:created_at).last
    assert_redirected_to task_path(task)
    assert_equal task.id, payment.reload.task_id
    assert_equal "Secure Delivery", task.package_type
  end

  test "GET /tasks filters by priority" do
    urgent = tasks(:one)
    express = tasks(:task_one)

    get tasks_path(priority: "urgent")

    assert_response :success
    assert_select "turbo-frame##{dom_id(urgent)}", count: 1
    assert_select "turbo-frame##{dom_id(express)}", count: 0
  end

  test "GET /tasks/payment/cancel re-renders new with stored form" do
    token = "cancel123"
    payment = Payment.create!(
      provider: "stripe",
      amount_cents: 2500,
      currency: "USD",
      payable: @customer,
      category: :service_fee,
      payment_type: :per_task,
      metadata: {
        "task_cancel_token" => token,
        "task_form" => {
          "customer_id" => @customer.id,
          "carrier_id" => @carrier.id,
          "package_type" => "Docs",
          "start" => "A",
          "target" => "B"
        },
        "payment_form" => {
          "amount" => "99",
          "currency" => "USD",
          "service_type" => "express_delivery",
          "description" => "Rush"
        }
      }
    )

    get task_payment_cancel_path, params: { token: token }

    assert_response :unprocessable_entity
    assert_select "input[name='payment[amount]'][value='99']"
    assert_select "select#payment_service_type option[selected][value='express_delivery']"
    assert_select "input[value='Docs']"
  ensure
    payment.destroy if payment.persisted?
  end
end
