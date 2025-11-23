require "test_helper"

class OdooSimpleTest < ActionDispatch::IntegrationTest
  setup do
    @valid_api_key = "test-key-456"
    @original_key = ENV["ODOO_API_KEY"]
    ENV["ODOO_API_KEY"] = @valid_api_key

    IntegrationEvent.where(provider: "odoo").delete_all
    Customer.where("email LIKE ?", "%odoo-simple%").delete_all
  end

  teardown do
    ENV["ODOO_API_KEY"] = @original_key
  end

  test "rejects without API key" do
    post_json api_v1_integrations_odoo_url, { id: 1 }
    assert_response :forbidden
  end

  test "rejects with wrong API key" do
    post_json api_v1_integrations_odoo_url, { id: 1 }, { "X-Odoo-Api-Key" => "wrong" }
    assert_response :forbidden
  end

  test "accepts with valid API key and creates customer" do
    payload = {
      id: 100,
      model: "res.partner",
      name: "Odoo Test Contact",
      email: "odoo-simple-test@example.com",
      phone: "+123456789",
      street: "123 Test St"
    }

    post_json api_v1_integrations_odoo_url, payload, { "X-Odoo-Api-Key" => @valid_api_key }
    assert_response :success

    customer = Customer.find_by(email: "odoo-simple-test@example.com")
    assert_not_nil customer
    assert_equal "Odoo Test Contact", customer.name
  end

  private

  def post_json(url, payload, headers = {})
    post url, params: payload.to_json, headers: headers.merge("Content-Type" => "application/json")
  end
end
