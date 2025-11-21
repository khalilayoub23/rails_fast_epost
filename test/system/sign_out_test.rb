require "application_system_test_case"

class SignOutTest < ApplicationSystemTestCase
  def setup
    User.delete_all
    @user = User.create!(email: "admin@example.com", password: "password", role: "admin")
  end

  test "user can sign out from the main navigation" do
    visit new_user_session_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password"
    click_button "Sign In"

    assert_text "Dashboard"

    find("button", text: "Logout", match: :first).click

    assert_text I18n.t("nav.login")
  end

  private

  # Skip loading the global fixtures for this system test to avoid unrelated
  # foreign key dependencies. The test creates the records it needs directly.
  def setup_fixtures; end
  def teardown_fixtures; end
end
