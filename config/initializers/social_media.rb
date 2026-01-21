# frozen_string_literal: true

# Load social media configuration with ERB support so we can inject ENV overrides
require "erb"

config_path = Rails.root.join("config", "social_media.yml")
raw_yaml = ERB.new(File.read(config_path)).result
parsed_config = YAML.safe_load(raw_yaml, aliases: true) || {}
env_config = parsed_config.fetch(Rails.env, {}).with_indifferent_access

if (phone_e164 = ENV["SOCIAL_CONTACT_PHONE_E164"].presence)
  digits = phone_e164.gsub(/[^0-9]/, "")

  if digits.present?
    env_config["whatsapp"] = "https://wa.me/#{digits}"
    env_config["telegram"] = "https://t.me/+#{digits}"
  end
end

SOCIAL_MEDIA_CONFIG = env_config.freeze
