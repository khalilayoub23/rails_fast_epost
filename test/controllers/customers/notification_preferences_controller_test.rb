require "test_helper"

class Customers::NotificationPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @preference = notification_preferences(:customer_sms_opt_in)
    sign_in users(:admin)
  end

  test "creates notification preference" do
    assert_difference -> { @customer.notification_preferences.count }, 1 do
      post customer_notification_preferences_path(@customer), params: {
        notification_preference: {
          channel: :in_app,
          enabled: true,
          quiet_hours_start: 22,
          quiet_hours_end: 6
        }
      }
    end

    assert_redirected_to customer_notification_preferences_path(@customer)
  end

  test "updates notification preference" do
    patch customer_notification_preference_path(@customer, @preference), params: {
      notification_preference: {
        enabled: false,
        quiet_hours_start: 8,
        quiet_hours_end: 20
      }
    }

    assert_redirected_to customer_notification_preferences_path(@customer)
    @preference.reload
    assert_not @preference.enabled?
    assert_equal 8, @preference.quiet_hours_start
    assert_equal 20, @preference.quiet_hours_end
  end

  test "destroys notification preference" do
    assert_difference -> { @customer.notification_preferences.count }, -1 do
      delete customer_notification_preference_path(@customer, @preference)
    end

    assert_redirected_to customer_notification_preferences_path(@customer)
  end

  test "prevents duplicate channels" do
    duplicate = @customer.notification_preferences.build(channel: :sms, enabled: true)

    assert_not duplicate.valid?
  end
end
