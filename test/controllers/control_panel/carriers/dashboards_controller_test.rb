require "test_helper"

class ControlPanel::Carriers::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:operations_manager)
    sign_in @user
  end

  test "renders dashboard" do
    get control_panel_carriers_dashboard_path
    assert_response :success
    assert_select "h2", text: /Task board/
  end

  test "requires carrier membership" do
    CarrierMembership.delete_all
    get control_panel_carriers_dashboard_path
    assert_redirected_to root_path
  end
end
