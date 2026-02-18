require "application_system_test_case"
require "securerandom"

class AuthenticationFlowTest < ApplicationSystemTestCase
  test "visitor can register via email" do
    visit new_user_registration_path

    email = "user_#{SecureRandom.hex(4)}@example.com"
    within "form#new_user" do
      fill_in "Full name", with: "System Test User"
      fill_in "Email", with: email
      fill_in "Password", with: "Password123!"
      fill_in "Confirm Password", with: "Password123!"
      submit_form_with_request_submit("form#new_user")
    end

    assert_text "Dashboard"
  end

  test "existing user can log in with email" do
    user = User.create!(
      email: "existing_#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      role: :sender,
      user_type: :sender,
      full_name: "Existing System User"
    )

    visit new_user_session_path
    within "form#new_user" do
      fill_in "Email", with: user.email
      fill_in "Password", with: "Password123!"
      submit_form_with_request_submit("form#new_user")
    end

    assert_text "Dashboard"
  end
end
