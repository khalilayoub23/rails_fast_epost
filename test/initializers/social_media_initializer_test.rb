require "test_helper"

class SocialMediaInitializerTest < ActiveSupport::TestCase
  setup do
    @original_phone = ENV["SOCIAL_CONTACT_PHONE_E164"]
    @original_config = SOCIAL_MEDIA_CONFIG.dup
  end

  teardown do
    ENV["SOCIAL_CONTACT_PHONE_E164"] = @original_phone

    if Object.const_defined?(:SOCIAL_MEDIA_CONFIG)
      Object.send(:remove_const, :SOCIAL_MEDIA_CONFIG)
    end

    Object.const_set(:SOCIAL_MEDIA_CONFIG, @original_config.freeze)
  end

  test "whatsapp and telegram links derive from env phone" do
    ENV["SOCIAL_CONTACT_PHONE_E164"] = "+972532426920"
    reload_social_media_initializer

    assert_equal "https://wa.me/972532426920", SOCIAL_MEDIA_CONFIG["whatsapp"]
    assert_equal "https://t.me/+972532426920", SOCIAL_MEDIA_CONFIG["telegram"]
  end

  private

  def reload_social_media_initializer
    Object.send(:remove_const, :SOCIAL_MEDIA_CONFIG) if Object.const_defined?(:SOCIAL_MEDIA_CONFIG)
    load Rails.root.join("config/initializers/social_media.rb")
  end
end
