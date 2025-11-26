require "test_helper"

class ControlPanel::Lawyers::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:operations_manager)
    sign_in @user
  end

  test "shows lawyer dashboard" do
    get control_panel_lawyers_dashboard_path(lawyer_id: lawyers(:lawyer_one).id)
    assert_response :success
    assert_select "h2", text: /Compliance rate/
  end
end
