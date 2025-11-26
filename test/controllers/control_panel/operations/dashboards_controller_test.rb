require "test_helper"

class ControlPanel::Operations::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:operations_manager)
    sign_in @user
  end

  test "renders operations dashboard" do
    get control_panel_operations_dashboard_path
    assert_response :success
    assert_select "h1", text: /Network Health Overview/
  end

  test "blocks non operations roles" do
    sign_out @user
    sign_in users(:viewer)

    get control_panel_operations_dashboard_path
    assert_redirected_to root_path
  end
end
