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
      assert_difference [ "Payment.count", "Customer.count", "Task.count" ], 1 do
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
    assert_includes captured_payload[:success_url], "token="
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

  test "rejects unsupported currency" do
    post checkout_path, params: {
      amount: "25",
      currency: "BTC",
      service_type: "standard",
      name: "Crypto Buyer",
      email: "crypto@example.com",
      phone: "+155555503",
      service_description: "Test"
    }

    assert_redirected_to new_checkout_path
    assert_match "Unsupported currency", flash[:alert]
  end

  test "normalizes lowercase currency for gateway" do
    session_struct = Struct.new(:id, :url, :payment_intent)
    session = session_struct.new("cs_test_currency", "https://checkout.stripe.com/pay/currency", "pi_test_currency")
    captured_payload = nil

    Stripe::Checkout::Session.stub(:create, ->(payload) { captured_payload = payload; session }) do
      post checkout_path, params: {
        amount: "10",
        currency: "usd",
        service_type: "standard",
        name: "Lowercase Currency",
        email: "currency@example.com",
        phone: "+155555504",
        service_description: "Test"
      }
    end

    assert_redirected_to "https://checkout.stripe.com/pay/currency"
    assert_equal "USD", captured_payload.dig(:line_items, 0, :price_data, :currency)
  end

  test "success page only loads payment details with valid token" do
    session_struct = Struct.new(:id, :url, :payment_intent)
    session = session_struct.new("cs_test_success_token", "https://checkout.stripe.com/pay/success", "pi_test_success_token")

    Stripe::Checkout::Session.stub(:create, ->(_payload) { session }) do
      post checkout_path, params: {
        amount: "15",
        currency: "USD",
        service_type: "standard",
        name: "Success Token",
        email: "success-token@example.com",
        phone: "+155555505",
        service_description: "Token test"
      }
    end

    payment = Payment.order(:created_at).last
    get checkout_success_path, params: { session_id: payment.checkout_session_id }
    assert_response :success
    assert_no_match "Reference", response.body

    get checkout_success_path, params: { session_id: payment.checkout_session_id, token: payment.metadata["success_token"] }
    assert_response :success
    assert_match "Reference", response.body
  end

  test "cancel requires valid token" do
    session_struct = Struct.new(:id, :url, :payment_intent)
    session = session_struct.new("cs_test_cancel_token", "https://checkout.stripe.com/pay/cancel", "pi_test_cancel_token")

    Stripe::Checkout::Session.stub(:create, ->(_payload) { session }) do
      post checkout_path, params: {
        amount: "20",
        currency: "USD",
        service_type: "standard",
        name: "Cancel Token",
        email: "cancel-token@example.com",
        phone: "+155555506",
        service_description: "Cancel test"
      }
    end

    payment = Payment.order(:created_at).last
    payment.update!(gateway_status: "pending")

    get checkout_cancel_path, params: { session_id: payment.checkout_session_id }
    assert_response :success
    assert_equal "pending", payment.reload.gateway_status

    get checkout_cancel_path, params: { token: "wrong-token" }
    assert_response :success
    assert_equal "pending", payment.reload.gateway_status

    get checkout_cancel_path, params: { token: payment.metadata["cancel_token"] }
    assert_response :success
    assert_equal "canceled", payment.reload.gateway_status
  end
end
