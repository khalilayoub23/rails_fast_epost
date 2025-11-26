require "application_system_test_case"
require "securerandom"

class AuthenticationFlowTest < ApplicationSystemTestCase
  test "visitor can register via email" do
    visit new_user_registration_path

    email = "user_#{SecureRandom.hex(4)}@example.com"
    fill_in "Email", with: email
    fill_in "Password", with: "Password123!"
    fill_in "Confirm Password", with: "Password123!"
    click_button "Create Account"

    assert_text "Dashboard"
    click_button "Logout"
  end

  test "existing user can log in with email" do
    user = users(:viewer)

    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign In"

    assert_text "Dashboard"
    click_button "Logout"
  end
end
