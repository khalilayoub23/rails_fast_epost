require "test_helper"
require "openssl"

class StripeExtraEventsTest < ActionDispatch::IntegrationTest
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

  test "charge.refunded sets status to refunded" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 1000,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { payment_intent_id: "pi_ref_1" }
    }
    assert_response :created

    # Note: for charge events, data.object.id is charge id, not PI. Our mapping finds by id first.
    event = { id: "evt_r1", type: "charge.refunded", data: { object: { id: "pi_ref_1" } } }.to_json
    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    p = Payment.find_by(provider: "stripe", external_id: "pi_ref_1")
    assert_equal "refunded", p.gateway_status
  end

  test "checkout.session.expired sets status to canceled" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 1000,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { checkout_session_id: "cs_exp_1" }
    }
    assert_response :created

    event = { id: "evt_cse", type: "checkout.session.expired", data: { object: { id: "cs_exp_1" } } }.to_json
    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    p = Payment.find_by(provider: "stripe", external_id: "cs_exp_1")
    assert_equal "canceled", p.gateway_status
  end
end
