require "test_helper"

class Messengers::NotificationPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @messenger = messengers(:messenger_one)
    @preference = notification_preferences(:messenger_sms_opt_in)
    sign_in users(:admin)
  end

  test "creates messenger preference" do
    assert_difference -> { @messenger.notification_preferences.count }, 1 do
      post messenger_notification_preferences_path(@messenger), params: {
        notification_preference: {
          channel: :in_app,
          enabled: false
        }
      }
    end

    assert_redirected_to messenger_notification_preferences_path(@messenger)
  end

  test "denies access to non manager" do
    sign_out :user
    sign_in users(:viewer)

    post messenger_notification_preferences_path(@messenger), params: { notification_preference: { channel: :sms, enabled: true } }

    assert_redirected_to root_path
  end
end
