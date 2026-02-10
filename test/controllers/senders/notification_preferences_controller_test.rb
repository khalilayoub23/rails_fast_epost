require "test_helper"

class Senders::NotificationPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sender = senders(:sender_one)
    @preference = notification_preferences(:sender_sms_muted)
    sign_in users(:admin)
  end

  test "updates sender preference" do
    patch sender_notification_preference_path(@sender, @preference), params: {
      notification_preference: {
        enabled: true,
        quiet_hours_start: nil,
        quiet_hours_end: nil
      }
    }

    assert_redirected_to sender_notification_preferences_path(@sender)
    assert @preference.reload.enabled?
  end

  test "destroys sender preference" do
    assert_difference -> { @sender.notification_preferences.count }, -1 do
      delete sender_notification_preference_path(@sender, @preference)
    end

    assert_redirected_to sender_notification_preferences_path(@sender)
  end

  test "denies access to non manager" do
    sign_out :user
    sign_in users(:viewer)

    patch sender_notification_preference_path(@sender, @preference), params: {
      notification_preference: {
        enabled: true,
        quiet_hours_start: nil,
        quiet_hours_end: nil
      }
    }

    assert_redirected_to root_path
  end
end
