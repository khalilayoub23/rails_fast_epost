require "application_system_test_case"
require "securerandom"

class AuthFlowsTest < ApplicationSystemTestCase
  def setup
    User.destroy_all
    @viewer = User.create!(email: "viewer@example.com", password: "password", role: "sender", user_type: :sender)
    @admin = User.create!(email: "admin@example.com", password: "password", role: "admin")
  end

  test "viewer lands on dashboard after email login" do
    visit new_user_session_path

    within "form#new_user" do
      fill_in "user_email", with: @viewer.email
      fill_in "user_password", with: "password"
      submit_devise_form
    end

    assert_current_path dashboard_path
    assert_text I18n.t("dashboard_title", default: "Dashboard")
  end

  test "admin lands on main dashboard after login" do
    visit new_user_session_path

    within "form#new_user" do
      fill_in "user_email", with: @admin.email
      fill_in "user_password", with: "password"
      submit_devise_form
    end

    assert_current_path dashboard_path
    assert_text I18n.t("dashboard_title", default: "Dashboard")
  end

  test "new signup redirects straight to dashboard" do
    visit new_user_registration_path

    unique_email = "new-user-#{SecureRandom.hex(4)}@example.com"

    within "form#new_user" do
      fill_in "user_email", with: unique_email
      fill_in "user_password", with: "strong-password"
      fill_in "user_password_confirmation", with: "strong-password"
      submit_devise_form
    end

    assert_current_path dashboard_path
    assert_text I18n.t("dashboard_title", default: "Dashboard")
  end

  test "social connect options are visible" do
    configured_providers = Devise.omniauth_configs.keys
    skip "OmniAuth providers not configured" if configured_providers.blank?

    visit new_user_session_path

    configured_providers.each do |provider|
      path = "/users/auth/#{provider}"
      label = provider.to_s.titleize
      assert_selector "form[action='#{path}'] button", text: /#{Regexp.escape(label)}/i
    end
  end

  private

  def submit_devise_form
    find(:css, "button[type='submit'],input[type='submit']", match: :first).click
  end

  def setup_fixtures(*); end
  def teardown_fixtures(*); end
end
