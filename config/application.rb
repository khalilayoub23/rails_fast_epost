require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FastEpost3
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # I18n configuration for multi-language support
    config.i18n.available_locales = [ :en, :ar, :ru, :he ]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    config.x.deliveries = ActiveSupport::OrderedOptions.new
    signature_env = ENV["REQUIRE_DELIVERY_SIGNATURES"]
    default_requirement = Rails.env.production?
    config.x.deliveries.require_saved_signatures = if signature_env.nil?
      default_requirement
    else
      ActiveModel::Type::Boolean.new.cast(signature_env)
    end
  end
end
