require "test_helper"

class IntegrationsWebhookSecurityTest < ActionDispatch::IntegrationTest
  setup do
    ENV["META_VERIFY_TOKEN"] = "meta_verify_secret"
    ENV["ODOO_API_KEY"] = "odoo_shared_secret"
    ENV["TELEGRAM_SECRET_TOKEN"] = "telegram_secret_token"
  end

  test "meta verify rejects mismatched token safely" do
    get "/api/v1/integrations/facebook", params: {
      "hub.mode" => "subscribe",
      "hub.verify_token" => "x",
      "hub.challenge" => "123"
    }

    assert_response :forbidden
  end

  test "meta verify accepts valid token" do
    get "/api/v1/integrations/facebook", params: {
      "hub.mode" => "subscribe",
      "hub.verify_token" => "meta_verify_secret",
      "hub.challenge" => "123"
    }

    assert_response :success
    assert_equal "123", response.body
  end

  test "odoo webhook rejects invalid api key" do
    post "/api/v1/integrations/odoo", params: { event: "ping" }.to_json, headers: {
      "CONTENT_TYPE" => "application/json",
      "X-Odoo-Api-Key" => "bad"
    }

    assert_response :forbidden
  end

  test "telegram webhook rejects invalid secret token" do
    post "/api/v1/integrations/telegram", params: { update_id: 1 }.to_json, headers: {
      "CONTENT_TYPE" => "application/json",
      "X-Telegram-Bot-Api-Secret-Token" => "bad"
    }

    assert_response :forbidden
  end
end
