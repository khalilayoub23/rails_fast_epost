# frozen_string_literal: true

# Load social media configuration
SOCIAL_MEDIA_CONFIG = YAML.load_file(Rails.root.join("config", "social_media.yml"))[Rails.env].freeze
