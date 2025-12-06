require "test_helper"

class UserLocaleLogoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :all

  setup do
    @user = users(:admin)
  end

  test "user can logout via delete request with locale parameter" do
    sign_in @user

    delete destroy_user_session_path(locale: :he)

    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_select "form#new_user"
  end
end
