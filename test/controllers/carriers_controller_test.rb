require "test_helper"

class CarriersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    sign_in @user
  end

  test "should get index" do
    get carriers_url
    assert_response :success
  end

  test "should get show" do
    # use a fixture carrier
    carrier = carriers(:one)
    get carrier_url(carrier)
    assert_response :success
  end

  test "should get new" do
    get new_carrier_url
    assert_response :success
  end

  test "should get create" do
  # perform a POST to create
  post carriers_url, params: { carrier: { carrier_type: "RegularCarrier", name: "New", email: "n@example.com", address: "Addr" } }
    assert_response :redirect
  end

  test "should get edit" do
    carrier = carriers(:one)
    get edit_carrier_url(carrier)
    assert_response :success
  end

  test "should get update" do
    carrier = carriers(:one)
    patch carrier_url(carrier), params: { carrier: { name: "Updated" } }
    assert_response :redirect
  end

  test "should get destroy" do
    carrier = carriers(:three)  # Use carrier without messengers
    delete carrier_url(carrier)
    assert_response :redirect
  end
end
