require "test_helper"
require "openssl"

class StripeEventsTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @task = tasks(:one)
    ENV["STRIPE_WEBHOOK_SECRET"] ||= "whsec_test"
  end

  def sign_stripe(payload)
    ts = Time.now.to_i
    v1 = OpenSSL::HMAC.hexdigest("SHA256", ENV["STRIPE_WEBHOOK_SECRET"], "t=#{ts}.#{payload}")
    "t=#{ts},v1=#{v1}"
  end

  test "payment_intent.succeeded updates status to succeeded" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 1000,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { payment_intent_id: "pi_test_123" }
    }
    assert_response :created

    event = {
      id: "evt_1",
      type: "payment_intent.succeeded",
      data: { object: { id: "pi_test_123" } }
    }.to_json

    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    p = Payment.find_by(provider: "stripe", external_id: "pi_test_123")
    assert_equal "succeeded", p.gateway_status
  end

  test "payment_intent.payment_failed updates status to failed" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 1000,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { payment_intent_id: "pi_test_999" }
    }
    assert_response :created

    event = {
      id: "evt_2",
      type: "payment_intent.payment_failed",
      data: { object: { id: "pi_test_999" } }
    }.to_json

    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    p = Payment.find_by(provider: "stripe", external_id: "pi_test_999")
    assert_equal "failed", p.gateway_status
  end
end
