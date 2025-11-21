require "application_system_test_case"

class SocialLinksTest < ApplicationSystemTestCase
  test "whatsapp and telegram links reflect shared phone number" do
    visit root_path(locale: :en)

    assert_selector "a[href='https://wa.me/972532426920']"
    assert_selector "a[href='https://t.me/+972532426920']"
  end
end
