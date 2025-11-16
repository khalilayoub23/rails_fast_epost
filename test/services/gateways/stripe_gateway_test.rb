require "test_helper"
require "minitest/mock"

module Gateways
  class StripeGatewayTest < ActiveSupport::TestCase
    setup do
      @task = tasks(:one)
      @customer = customers(:one)
      Rails.configuration.x.stripe.secret_key = "sk_test_123"
    end

    teardown do
      Rails.configuration.x.stripe.secret_key = nil
    end

    test "creates checkout session when missing identifiers" do
      session_struct = Struct.new(:id, :url, :payment_intent)
      session = session_struct.new("cs_test_123", "https://checkout.stripe.com/c/test", "pi_test_123")

      Stripe::Checkout::Session.stub(:create, session) do
        payment = nil
        assert_difference("Payment.count", 1) do
          payment = Gateways::StripeGateway.create_payment!(
            amount_cents: 2500,
            currency: "USD",
            task: @task,
            payable: @customer,
            metadata: { "success_url" => "https://app.example.com/pay/success" }
          )
        end

        assert_equal "stripe", payment.provider
        assert_equal "cs_test_123", payment.external_id
        assert_equal "cs_test_123", payment.checkout_session_id
        assert_equal "pi_test_123", payment.payment_intent_id
        assert_equal "https://checkout.stripe.com/c/test", payment.payment_url
        assert_equal "pending", payment.gateway_status
        assert_equal "https://app.example.com/pay/success", payment.metadata["success_url"]
      end
    end

    test "reuses provided metadata without remote call" do
      metadata = {
        checkout_session_id: "cs_manual_1",
        payment_intent_id: "pi_manual_1",
        checkout_url: "https://pay.example.com/manual"
      }

      Stripe::Checkout::Session.stub(:create, ->(*) { raise "Stripe should not be invoked" }) do
        payment = nil
        assert_difference("Payment.count", 1) do
          payment = Gateways::StripeGateway.create_payment!(
            amount_cents: 5100,
            currency: "USD",
            task: @task,
            payable: @customer,
            metadata: metadata
          )
        end

        assert_equal "cs_manual_1", payment.external_id
        assert_equal "cs_manual_1", payment.checkout_session_id
        assert_equal "pi_manual_1", payment.payment_intent_id
        assert_equal "https://pay.example.com/manual", payment.payment_url
        assert_equal "cs_manual_1", payment.metadata["checkout_session_id"]
      end
    end
  end
end
