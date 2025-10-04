# Stripe global configuration
if ENV["STRIPE_SECRET_KEY"].present?
  require "stripe"
  Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  Stripe.max_network_retries = 2
  Stripe.app_info = {
    name: "RailsFastEpost",
    version: "1.0",
    url: "https://example.com",
    partner_id: nil
  }
end
