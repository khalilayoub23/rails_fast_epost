require "application_system_test_case"

class UserRolesTest < ApplicationSystemTestCase
  test "admin sees Admin role in topbar" do
    login_as users(:admin)
    visit dashboard_path
    assert_text "Welcome"
    assert_text users(:admin).full_name
  end

  test "manager sees Manager role in topbar" do
    login_as users(:manager)
    visit dashboard_path
    assert_text "Welcome"
    assert_text users(:manager).full_name
  end

  test "operations manager sees Operations Manager role in topbar" do
    login_as users(:operations_manager)
    visit dashboard_path
    assert_text "Welcome"
    assert_text users(:operations_manager).full_name
  end

  test "viewer sees Viewer role in topbar" do
    login_as users(:viewer)
    visit dashboard_path
    assert_text "Welcome"
    assert_text users(:viewer).full_name
  end
end
