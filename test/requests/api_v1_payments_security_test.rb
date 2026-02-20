require "test_helper"

class ApiV1PaymentsSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @task = tasks(:one)
    @payment = Payment.create!(
      provider: "stripe",
      payable: @customer,
      task: @task,
      category: :service_fee,
      payment_type: :per_task,
      amount_cents: 1000,
      currency: "USD",
      gateway_status: :pending
    )
    ENV["LOCALPAY_APP_SECRET"] = "localpay_test_secret"
  end

  test "refund endpoint rejects unauthorized requests" do
    post "/api/v1/payments/#{@payment.id}/refund"
    assert_response :forbidden
  end

  test "refund endpoint accepts valid shared secret" do
    Gateways::StripeGateway.stub :refund!, true do
      post "/api/v1/payments/#{@payment.id}/refund", headers: { "X-Internal-Api-Secret" => "localpay_test_secret" }
      assert_response :success
    end
  end

  test "refund endpoint rejects wrong-length shared secret safely" do
    post "/api/v1/payments/#{@payment.id}/refund", headers: { "X-Internal-Api-Secret" => "x" }
    assert_response :forbidden
  end

  test "create rejects unsupported currency" do
    post "/api/v1/payments", params: {
      provider: "local",
      amount_cents: 500,
      currency: "BTC",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id
    }

    assert_response :unprocessable_entity
  end

  test "create rejects non-positive amount" do
    post "/api/v1/payments", params: {
      provider: "local",
      amount_cents: 0,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id
    }

    assert_response :unprocessable_entity
  end

  test "webhook rejects invalid json payload" do
    post "/api/v1/payments/local/webhook", params: "{bad", headers: { "CONTENT_TYPE" => "text/plain" }
    assert_response :bad_request
  end
end
