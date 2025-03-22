require "test_helper"

class CarriersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get carriers_index_url
    assert_response :success
  end

  test "should get show" do
    get carriers_show_url
    assert_response :success
  end

  test "should get new" do
    get carriers_new_url
    assert_response :success
  end

  test "should get create" do
    get carriers_create_url
    assert_response :success
  end

  test "should get edit" do
    get carriers_edit_url
    assert_response :success
  end

  test "should get update" do
    get carriers_update_url
    assert_response :success
  end

  test "should get destroy" do
    get carriers_destroy_url
    assert_response :success
  end
end
