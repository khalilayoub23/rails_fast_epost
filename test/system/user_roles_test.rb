require "application_system_test_case"

class UserRolesTest < ApplicationSystemTestCase
  test "admin sees Admin role in topbar" do
    login_as users(:admin)
    visit root_path
    assert_text "Admin"
  end

  test "manager sees Manager role in topbar" do
    login_as users(:manager)
    visit root_path
    assert_text "Manager"
  end

  test "operations manager sees Operations Manager role in topbar" do
    login_as users(:operations_manager)
    visit root_path
    assert_text "Operations Manager"
  end

  test "viewer sees Viewer role in topbar" do
    login_as users(:viewer)
    visit root_path
    assert_text "Viewer"
  end
end
