require "test_helper"

class ControlPanel::Senders::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:operations_manager)
    sign_in @user
  end

  test "shows sender dashboard" do
    get control_panel_senders_dashboard_path(sender_id: senders(:sender_two).id)
    assert_response :success
    assert_select "h2", text: /Carrier mix/
  end
end
