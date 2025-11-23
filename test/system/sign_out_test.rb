require "application_system_test_case"

class SignOutTest < ApplicationSystemTestCase
  def setup
    User.delete_all
    @user = User.create!(email: "admin@example.com", password: "password", role: "admin")
  end

  test "user can sign out from the main navigation" do
    visit new_user_session_path
    within "form#new_user" do
      fill_in "user_email", with: @user.email
      fill_in "user_password", with: "password"
      find(:css, "button[type='submit'],input[type='submit']", match: :first).click
    end

    assert_text "Dashboard"

    find("button", text: /logout/i, match: :first).click

    assert_current_path new_user_session_path
    assert_text "Sign in to your account"
  end

  private

  # Skip loading the global fixtures for this system test to avoid unrelated
  # foreign key dependencies. The test creates the records it needs directly.
  def setup_fixtures; end
  def teardown_fixtures; end
end
