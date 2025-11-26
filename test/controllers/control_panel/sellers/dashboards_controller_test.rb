require "test_helper"

class ControlPanel::Sellers::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:operations_manager)
    sign_in @user
  end

  test "shows seller dashboard" do
    seller = senders(:sender_two)
    get control_panel_sellers_dashboard_path(seller_id: seller.id)
    assert_response :success
    assert_select "h2", text: /SLA breaches/
  end
end
