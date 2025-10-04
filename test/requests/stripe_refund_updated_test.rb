require "test_helper"
require "openssl"

class StripeRefundUpdatedTest < ActionDispatch::IntegrationTest
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

  test "charge.refund.updated sets status to refunded" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 1000,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { payment_intent_id: "pi_refupd_1" }
    }
    assert_response :created

    event = { id: "evt_rupd", type: "charge.refund.updated", data: { object: { id: "pi_refupd_1" } } }.to_json
    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    p = Payment.find_by(provider: "stripe", external_id: "pi_refupd_1")
    assert_equal "refunded", p.gateway_status
  end
end
