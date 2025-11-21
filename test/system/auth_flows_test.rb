require "application_system_test_case"
require "securerandom"

class AuthFlowsTest < ApplicationSystemTestCase
  def setup
    User.delete_all
    @viewer = User.create!(email: "viewer@example.com", password: "password", role: "viewer")
    @admin = User.create!(email: "admin@example.com", password: "password", role: "admin")
  end

  test "viewer lands on dashboard after email login" do
    visit new_user_session_path

    fill_in "Email", with: @viewer.email
    fill_in "Password", with: "password"
    click_on "Sign In"

    assert_current_path dashboard_path
    assert_text I18n.t("dashboard_title", default: "Dashboard")
  end

  test "admin lands on admin dashboard after login" do
    visit new_user_session_path

    fill_in "Email", with: @admin.email
    fill_in "Password", with: "password"
    click_on "Sign In"

    assert_current_path admin_dashboard_path
    assert_text "Admin Dashboard"
  end

  test "new signup redirects straight to dashboard" do

    visit new_user_registration_path

    unique_email = "new-user-#{SecureRandom.hex(4)}@example.com"

    fill_in "Email", with: unique_email
    fill_in "Password", with: "strong-password"
    fill_in "Confirm Password", with: "strong-password"
    click_on "Create Account"

    assert_current_path dashboard_path
    assert_text I18n.t("dashboard_title", default: "Dashboard")
  end

  test "social connect options are visible" do
    configured_providers = Devise.omniauth_configs.keys
    skip "OmniAuth providers not configured" if configured_providers.blank?

    visit new_user_session_path

    configured_providers.each do |provider|
      path = omniauth_authorize_path(:user, provider)
      label = provider.to_s.titleize
      assert_selector "form[action='#{path}'] button", text: /#{Regexp.escape(label)}/i
    end
  end

  private

  def setup_fixtures(*); end
  def teardown_fixtures(*); end
end
