# Stripe global configuration
Rails.configuration.x.stripe ||= ActiveSupport::OrderedOptions.new



require "stripe"

Rails.configuration.x.stripe.secret_key = ENV["STRIPE_SECRET_KEY"]
Rails.configuration.x.stripe.publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"]

if Rails.configuration.x.stripe.secret_key.present?
  Stripe.api_key = Rails.configuration.x.stripe.secret_key
  Stripe.max_network_retries = 2
  Stripe.app_info = {
    name: "RailsFastEpost",
    version: "1.0",
    url: "https://example.com",
    partner_id: nil
  }
end
