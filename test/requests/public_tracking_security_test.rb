require "test_helper"

class PublicTrackingSecurityTest < ActionDispatch::IntegrationTest
  setup do
    ENV["PUBLIC_TRACKING_API_KEY"] = "public_tracking_secret"
  end

  test "tracking endpoint rejects missing api key" do
    get "/api/v1/public/track/BARCODE1"
    assert_response :forbidden
  end

  test "tracking endpoint rejects wrong-length api key safely" do
    get "/api/v1/public/track/BARCODE1", headers: { "X-Public-Api-Key" => "x" }
    assert_response :forbidden
  end

  test "tracking endpoint accepts valid api key" do
    get "/api/v1/public/track/BARCODE1", headers: { "X-Public-Api-Key" => "public_tracking_secret" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal "BARCODE1", body.dig("data", "barcode")
  end
end
