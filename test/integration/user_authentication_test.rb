require "test_helper"
require "securerandom"

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  test "user can log in with valid credentials" do
    user = users(:admin)

    post user_session_path, params: { user: { email: user.email, password: "password" } }
    assert_response :see_other

    follow_redirect!
    assert_response :success
    assert_select "h2", /dashboard|overview/i
  end

  test "login form renders without authentication" do
    get new_user_session_path
    assert_response :success
    assert_select "form#new_user"
  end

  test "login failure re-renders the form" do
    user = users(:admin)

    post user_session_path, params: { user: { email: user.email, password: "wrong" } }
    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "user can sign up and access dashboard" do
    email = "signup-#{SecureRandom.hex(4)}@example.com"

    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          email: email,
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :redirect
    follow_redirect!
    assert_response :success

    get dashboard_path
    assert_response :success
    assert_select "h2", /dashboard|overview/i
  end

  test "user can log out and log back in after signing up" do
    email = "returning-#{SecureRandom.hex(4)}@example.com"
    password = "password123"

    post user_registration_path, params: {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    follow_redirect!
    assert_response :success

    delete destroy_user_session_path
    follow_redirect!
    assert_response :success

    post user_session_path, params: { user: { email: email, password: password } }
    assert_response :see_other

    follow_redirect!
    assert_response :success
    assert_select "h2", /dashboard|overview/i
  end

  test "header shows Sign Up button when on login page" do
    get new_user_session_path
    assert_response :success
    # The text might vary based on default locale, but we check for the link target
    assert_select "a[href=?]", new_user_registration_path
  end

  test "header shows Login button when on home page" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", new_user_session_path
  end

  test "header shows Hebrew Sign Up button when on login page in Hebrew" do
    get new_user_session_path(locale: :he)
    assert_response :success
    assert_select "a[href=?]", new_user_registration_path
    assert_select "a", text: "הרשמה"
  end

  test "header shows Hebrew Login button when on sign up page in Hebrew" do
    get new_user_registration_path(locale: :he)
    assert_response :success
    assert_select "a[href=?]", new_user_session_path
    assert_select "a", text: "התחברות"
  end

  test "login form has prominent sign up button" do
    get new_user_session_path
    assert_response :success
    # Check for the new button we added (looking for the text in the link)
    assert_select "a[href=?]", new_user_registration_path
  end

  test "signup form has prominent login button" do
    get new_user_registration_path
    assert_response :success
    # Check for the new button we added
    assert_select "a[href=?]", new_user_session_path
  end

  test "navigation links are translated based on locale" do
    # Test English
    get root_path(locale: :en)
    assert_response :success
    assert_select "a.landing-nav__link", text: "Services"
    assert_select "a.landing-nav__link", text: "Track Parcel"

    # Test Hebrew
    get root_path(locale: :he)
    assert_response :success
    assert_select "a.landing-nav__link", text: "שירותים"
    assert_select "a.landing-nav__link", text: "מעקב חבילה"
  end

  test "privacy policy link is present in header and page loads" do
    get root_path
    assert_response :success
    assert_select "a.landing-nav__link[href=?]", pages_privacy_policy_path

    get pages_privacy_policy_path
    assert_response :success
    # The title might vary based on locale, but "Privacy Policy" is the English default
    assert_select "h1", text: /Privacy Policy/i
  end
end
