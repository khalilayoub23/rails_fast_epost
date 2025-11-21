require "test_helper"

class NotifiableTest < ActiveSupport::TestCase
  setup do
    @customer = customers(:one)
  end

  test "preferred_notification_channel falls back to email" do
    @customer.notification_preferences.destroy_all

    assert_equal :email, @customer.preferred_notification_channel
  end

  test "preferred_notification_channel returns first enabled channel" do
    @customer.notification_preferences.destroy_all
    @customer.notification_preferences.create!(channel: :sms, enabled: true)

    assert_equal :sms, @customer.preferred_notification_channel
  end
end
