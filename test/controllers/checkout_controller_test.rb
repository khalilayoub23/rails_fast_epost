require "test_helper"
require "minitest/mock"

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_secret = Rails.configuration.x.try(:stripe).try(:secret_key)
    Rails.configuration.x.stripe.secret_key = "sk_test_checkout"
  end

  teardown do
    Rails.configuration.x.stripe.secret_key = @original_secret
  end

  test "shows checkout form" do
    get new_checkout_path
    assert_response :success
  end

  test "creates stripe payment and redirects to hosted checkout" do
    session_struct = Struct.new(:id, :url, :payment_intent)
    session = session_struct.new("cs_test_public", "https://checkout.stripe.com/pay/test", "pi_test_public")
    captured_payload = nil

    Stripe::Checkout::Session.stub(:create, ->(payload) { captured_payload = payload; session }) do
      assert_difference ["Payment.count", "Customer.count", "Task.count"], 1 do
        post checkout_path, params: {
          amount: "99.50",
          service_type: "express",
          name: "Checkout User",
          email: "checkout-user@example.com",
          phone: "+155555501",
          service_description: "Urgent legal delivery"
        }
      end
    end

    assert_redirected_to "https://checkout.stripe.com/pay/test"
    payment = Payment.order(:created_at).last
    assert_equal "stripe", payment.provider
    assert_equal "checkout-user@example.com", payment.metadata["customer_email"]
    assert_equal "cs_test_public", payment.checkout_session_id
    assert_includes captured_payload[:cancel_url], "token="
  end

  test "rejects zero amount" do
    post checkout_path, params: {
      amount: "0",
      service_type: "standard",
      name: "Zero Amount",
      email: "zero@example.com",
      phone: "+155555502",
      service_description: "Test"
    }

    assert_redirected_to new_checkout_path
    assert_match "Amount must be greater than zero", flash[:alert]
  end
end
