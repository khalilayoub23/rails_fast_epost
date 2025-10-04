require "test_helper"

class PaymentsApiValidationTest < ActionDispatch::IntegrationTest
  test "unsupported provider returns 422" do
    post "/api/v1/payments", params: { provider: "unknown", amount_cents: 1000, currency: "USD" }
    assert_response :unprocessable_entity
    json = JSON.parse(@response.body)
    assert_equal "Unsupported provider", json["error"]
  end

  test "missing payable or task returns 422 due to validations" do
    post "/api/v1/payments", params: { provider: "local", amount_cents: 500, currency: "USD" }
    assert_response :unprocessable_entity
    json = JSON.parse(@response.body)
    assert_includes Array(json["error"]).join(" "), "Payable"
  end

  test "missing amount rejects with 422" do
    post "/api/v1/payments", params: { provider: "local", currency: "USD" }
    # Our gateway validates amount_cents > 0 at model level; creation should fail
    assert_response :unprocessable_entity
  end
end
