require "test_helper"
require "securerandom"

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  test "user can log in with valid credentials" do
    user = users(:admin)

    post user_session_path, params: { user: { email: user.email, password: "password" } }
    assert_response :see_other

    follow_redirect!
    assert_response :success
    assert_select "h2", /dashboard/i
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
    assert_select "h2", /dashboard/i
  end
end
