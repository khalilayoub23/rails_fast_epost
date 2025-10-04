require "test_helper"
require "base64"
require "openssl"

class PaymentsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @task = tasks(:one)
    # Ensure secrets exist for signature tests
    ENV["LOCALPAY_APP_SECRET"] ||= "testsecret"
    ENV["STRIPE_WEBHOOK_SECRET"] ||= "whsec_test"
  end

  test "local checkout page responds" do
    # Create a local payment via API to generate an external_id and URL
    post "/api/v1/payments", params: {
      provider: "local",
      amount_cents: 1234,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id
    }
    assert_response :created
    body = JSON.parse(@response.body)
    url = body["payment_url"]
    assert_includes url, "/pay/local/"

    # Hit the checkout page
    get url
    assert_response :success
  end

  test "stripe success and cancel endpoints respond" do
    get "/pay/success"
    assert_response :success
    assert_match "success", @response.body.downcase

    get "/pay/cancel"
    assert_response :success
    assert_match "canceled", @response.body.downcase
  end

  test "local webhook with signature" do
    # Create payment first
    post "/api/v1/payments", params: {
      provider: "local",
      amount_cents: 2000,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id
    }
    assert_response :created
    payment = JSON.parse(@response.body)
    external_id = payment["external_id"]

    # Build signed payload
    raw = { id: external_id, status: "succeeded" }.to_json
    secret = ENV["LOCALPAY_APP_SECRET"].presence || "testsecret"
    signature = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, raw))

  post "/api/v1/payments/local/webhook", headers: { "X-Signature" => signature, "CONTENT_TYPE" => "application/json" }, params: raw
  assert_response :success
  json = JSON.parse(@response.body)
  assert_equal true, json["ok"]
  assert_equal Payment.find_by(provider: "local", external_id: external_id)&.id, json["id"]
  end

  test "stripe webhook with signature" do
    # Create a pending stripe payment (no real Stripe call needed in test)
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 5000,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { checkout_session_id: "cs_test_123" }
    }
    assert_response :created
    payment = JSON.parse(@response.body)
    external_id = payment["external_id"]

    # Craft a minimal Stripe event payload
    event = {
      id: "evt_test_123",
      type: "checkout.session.completed",
      data: { object: { id: external_id } }
    }.to_json

    # Stripe signature: v1 HMAC over "t=TS.payload"
  secret = ENV["STRIPE_WEBHOOK_SECRET"].presence || "whsec_test"
    ts = Time.now.to_i
    signed_payload = "t=#{ts}.#{event}"
    v1 = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
    header = "t=#{ts},v1=#{v1}"

  post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    # Ensure payment status updated
    p = Payment.find_by(provider: "stripe", external_id: external_id)
    assert_equal "succeeded", p.gateway_status
  end
end
