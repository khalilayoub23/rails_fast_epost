require "test_helper"

class OdooIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @valid_api_key = "test-odoo-key-123"
    @original_key = ENV["ODOO_API_KEY"]
    ENV["ODOO_API_KEY"] = @valid_api_key

    # Clean up any existing test data
    IntegrationEvent.where(provider: "odoo").delete_all
    Customer.where(email: "odoo-test@example.com").delete_all
  end

  teardown do
    ENV["ODOO_API_KEY"] = @original_key
  end

  test "rejects request without API key" do
    post api_v1_integrations_odoo_url, params: { id: 1, model: "res.partner" }, as: :json

    assert_response :forbidden
  end

  test "rejects request with invalid API key" do
    post api_v1_integrations_odoo_url,
         params: { id: 1, model: "res.partner" },
         headers: { "X-Odoo-Api-Key" => "wrong-key" },
         as: :json

    assert_response :forbidden
  end

  test "accepts request with valid API key" do
    post api_v1_integrations_odoo_url,
         params: {
           id: 123,
           model: "res.partner",
           name: "Test Contact",
           email: "odoo-test@example.com",
           phone: "+1234567890"
         },
         headers: { "X-Odoo-Api-Key" => @valid_api_key },
         as: :json

    assert_response :success
  end

  test "creates integration event for valid contact webhook" do
    assert_difference "IntegrationEvent.count", 1 do
      post api_v1_integrations_odoo_url,
           params: {
             id: 456,
             model: "res.partner",
             name: "Odoo Contact",
             email: "contact@odoo-test.com"
           },
           headers: { "X-Odoo-Api-Key" => @valid_api_key },
           as: :json
    end

    event = IntegrationEvent.last
    assert_equal "odoo", event.provider
    assert_equal "456", event.external_id
    assert event.status_processed?
  end

  test "creates customer from Odoo contact payload" do
    assert_difference "Customer.count", 1 do
      post api_v1_integrations_odoo_url,
           params: {
             id: 789,
             model: "res.partner",
             name: "John Doe",
             email: "john.doe@odootest.com",
             phone: "+9876543210",
             street: "123 Main St"
           },
           headers: { "X-Odoo-Api-Key" => @valid_api_key },
           as: :json
    end

    customer = Customer.find_by(email: "john.doe@odootest.com")
    assert_not_nil customer
    assert_equal "John Doe", customer.name
    assert_includes customer.phones, "+9876543210"
    assert_equal "123 Main St", customer.address
  end

  test "updates existing customer from Odoo contact" do
    existing = Customer.create!(
      email: "existing@odoo.com",
      name: "Old Name",
      address: "Old Address",
      category: :business,
      phones: ["+15550000000"]
    )

    assert_no_difference "Customer.count" do
      post api_v1_integrations_odoo_url,
           params: {
             id: 999,
             model: "res.partner",
             name: "Updated Name",
             email: "existing@odoo.com",
             phone: "+1111111111"
           },
           headers: { "X-Odoo-Api-Key" => @valid_api_key },
           as: :json
    end

    existing.reload
    assert_equal "Updated Name", existing.name
    assert_includes existing.phones, "+1111111111"
  end

  test "processes Odoo lead payload" do
    # First create a customer for the lead
    Customer.create!(
      email: "lead-customer@odoo.com",
      name: "Lead Customer",
      address: "Lead Address",
      category: :business,
      phones: ["+16660000000"]
    )

    post api_v1_integrations_odoo_url,
         params: {
           id: 555,
           model: "crm.lead",
           name: "Potential Deal",
           email_from: "lead-customer@odoo.com",
           phone: "+5555555555",
           description: "Interested in our shipping services",
           stage: "New"
         },
         headers: { "X-Odoo-Api-Key" => @valid_api_key },
         as: :json

    assert_response :success
    event = IntegrationEvent.last
    assert_equal "odoo", event.provider
    assert event.status_processed?
  end

  test "handles missing email gracefully when name is present" do
    assert_difference "Customer.count", 1 do
      post api_v1_integrations_odoo_url,
           params: {
             id: 888,
             model: "res.partner",
             name: "No Email Contact",
             phone: "+3333333333"
           },
           headers: { "X-Odoo-Api-Key" => @valid_api_key },
           as: :json
    end

    customer = Customer.find_by(name: "No Email Contact")
    assert_not_nil customer
    assert_nil customer.email
  end

  test "skips duplicate webhook events by external_id" do
    # Send same event twice
    payload = {
      id: 777,
      model: "res.partner",
      name: "Duplicate Test",
      email: "duplicate@odoo.com"
    }
    headers = { "X-Odoo-Api-Key" => @valid_api_key }

    assert_difference "IntegrationEvent.count", 1 do
      post api_v1_integrations_odoo_url, params: payload, headers: headers, as: :json
      post api_v1_integrations_odoo_url, params: payload, headers: headers, as: :json
    end

    assert_equal 1, IntegrationEvent.where(provider: "odoo", external_id: "777").count
  end

  test "handles unknown model gracefully" do
    post api_v1_integrations_odoo_url,
         params: {
           id: 111,
           model: "unknown.model",
           name: "Unknown"
         },
         headers: { "X-Odoo-Api-Key" => @valid_api_key },
         as: :json

    assert_response :success
    event = IntegrationEvent.last
    assert event.status_processed?
  end
end
