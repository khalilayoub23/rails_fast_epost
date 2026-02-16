require "application_system_test_case"

class SignOutTest < ApplicationSystemTestCase
  test "user can sign out from the main navigation" do
    user = users(:admin)

    visit new_user_session_path
    within "form#new_user" do
      fill_in "user_email", with: user.email
      fill_in "user_password", with: "password"
      find(:css, "button[type='submit'],input[type='submit']", match: :first).click
    end

    assert_text "Dashboard"

    find("button", text: /logout/i, match: :first).click

    assert_current_path new_user_session_path
    assert_text "Sign in to your account"
  end
end
