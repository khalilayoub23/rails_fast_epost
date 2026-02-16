require "application_system_test_case"

class SocialLinksTest < ApplicationSystemTestCase
  test "whatsapp and telegram links reflect shared phone number" do
    visit root_path(locale: :en)

    assert_selector "a[href='#{SOCIAL_MEDIA_CONFIG['whatsapp']}']"
    assert_selector "a[href='#{SOCIAL_MEDIA_CONFIG['telegram']}']"
  end
end
