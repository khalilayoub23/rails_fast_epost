# frozen_string_literal: true

# Telegram bot configuration
# Reads TELEGRAM_BOT_TOKEN (for bot API) and TELEGRAM_SECRET_TOKEN (for webhook header verification)

TELEGRAM_BOT_TOKEN ||= (ENV["TELEGRAM_BOT_TOKEN"].presence || Rails.application.credentials.dig(:telegram, :bot_token) rescue nil)
TELEGRAM_SECRET_TOKEN ||= (ENV["TELEGRAM_SECRET_TOKEN"].presence || Rails.application.credentials.dig(:telegram, :secret_token) rescue nil)

def telegram_app_url
  ENV["APP_URL"].presence || ENV["HOST"].presence || "http://localhost:3000"
end

def telegram_webhook_url
  # Matches config/routes.rb: namespace :api => v1 => integrations => post "telegram" => telegram#receive
  base = telegram_app_url.to_s.sub(%r{/+$}, "")
  path = "/api/v1/integrations/telegram"
  base + path
end

Rails.logger.info("[Telegram] Bot token present: #{TELEGRAM_BOT_TOKEN.present? ? 'yes' : 'no'} | Secret token present: #{TELEGRAM_SECRET_TOKEN.present? ? 'yes' : 'no'} | Webhook: #{telegram_webhook_url}")
