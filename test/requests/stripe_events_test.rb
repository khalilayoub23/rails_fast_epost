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

  test "payment_intent.canceled updates status to canceled" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 1500,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { payment_intent_id: "pi_cancel_test" }
    }
    assert_response :created

    event = {
      id: "evt_cancel",
      type: "payment_intent.canceled",
      data: { object: { id: "pi_cancel_test" } }
    }.to_json

    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    payment = Payment.find_by(provider: "stripe", external_id: "pi_cancel_test")
    assert_equal "canceled", payment.gateway_status
  end

  test "checkout.session.async_payment_failed updates status to failed" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 3200,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { checkout_session_id: "cs_async_fail" }
    }
    assert_response :created

    event = {
      id: "evt_async_fail",
      type: "checkout.session.async_payment_failed",
      data: { object: { id: "cs_async_fail" } }
    }.to_json

    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    payment = Payment.find_by(provider: "stripe", external_id: "cs_async_fail")
    assert_equal "failed", payment.gateway_status
  end

  test "payment_intent.processing updates status to pending" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 2500,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { payment_intent_id: "pi_processing" }
    }
    assert_response :created

    payment = Payment.find_by(provider: "stripe", external_id: "pi_processing")
    payment.update!(gateway_status: "failed")

    event = {
      id: "evt_processing",
      type: "payment_intent.processing",
      data: { object: { id: "pi_processing" } }
    }.to_json

    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    payment.reload
    assert_equal "pending", payment.gateway_status
  end

  test "checkout.session.async_payment_succeeded updates status to succeeded" do
    post "/api/v1/payments", params: {
      provider: "stripe",
      amount_cents: 4200,
      currency: "USD",
      task_id: @task.id,
      payable_type: "Customer",
      payable_id: @customer.id,
      metadata: { checkout_session_id: "cs_async_success" }
    }
    assert_response :created

    Payment.where(provider: "stripe", external_id: "cs_async_success").update_all(gateway_status: "pending")

    event = {
      id: "evt_async_success",
      type: "checkout.session.async_payment_succeeded",
      data: { object: { id: "cs_async_success" } }
    }.to_json

    header = sign_stripe(event)
    post "/api/v1/payments/stripe/webhook", headers: { "Stripe-Signature" => header, "CONTENT_TYPE" => "application/json" }, params: event
    assert_response :success

    payment = Payment.find_by(provider: "stripe", external_id: "cs_async_success")
    assert_equal "succeeded", payment.gateway_status
  end
end
