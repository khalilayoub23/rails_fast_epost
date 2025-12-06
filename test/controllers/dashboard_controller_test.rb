require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manager = users(:manager)
    sign_in @manager
  end

  test "manager dashboard shows filters" do
    get dashboard_path
    assert_response :success

    assert_select "form[action='#{dashboard_path}'] select[name='payment_filter[status]']"
    assert_select "form[action='#{dashboard_path}'] select[name='task_filter[status]']"
  end
end
