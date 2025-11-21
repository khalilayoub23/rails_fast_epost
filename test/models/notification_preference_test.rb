require "test_helper"

class NotificationPreferenceTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @preference = notification_preferences(:messenger_quiet_hours)
  end

  test "quiet hours active respects window crossing midnight" do
    travel_to Time.zone.local(2025, 11, 18, 23, 0, 0) do
      assert @preference.quiet_hours_active?, "expected quiet hours to be active at 23:00"
    end

    travel_to Time.zone.local(2025, 11, 19, 7, 0, 0) do
      refute @preference.quiet_hours_active?, "expected quiet hours to end after 06:00"
    end
  end

  test "lookup returns preference for channel" do
    messenger = messengers(:messenger_one)

    result = NotificationPreference.lookup(messenger, :sms)

    assert_not_nil result
    assert_equal messenger, result.notifiable
    assert_equal "sms", result.channel
  end
end
