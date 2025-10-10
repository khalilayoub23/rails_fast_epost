require "net/http"
require "uri"
require "json"

namespace :integrations do
  desc "List required integration secrets"
  task secrets: :environment do
    required = {
      "META_VERIFY_TOKEN" => "Meta webhook verification token",
      "META_APP_SECRET" => "Meta app secret for X-Hub-Signature-256",
      "TELEGRAM_SECRET_TOKEN" => "Telegram secret header token",
      "TIKTOK_APP_SECRET" => "TikTok app secret for signature",
      "WEBSITES_SHARED_SECRET" => "Shared secret for generic websites (optional)"
    }

    puts "Required integration secrets:\n"
    required.each do |key, desc|
      val = ENV[key]
      status = val.present? ? "SET" : "MISSING"
      puts "- #{key}: #{status} (#{desc})"
    end
  end

  desc "Scaffold .env.local with integration secret placeholders if not present"
  task scaffold_env: :environment do
  path = Rails.root.join(".env.local")
    lines = []
    lines << "# Integration secrets" unless File.exist?(path)
    {
      "META_VERIFY_TOKEN" => "change-me",
      "META_APP_SECRET" => "change-me",
      "TELEGRAM_SECRET_TOKEN" => "change-me",
      "TIKTOK_APP_SECRET" => "change-me",
      "WEBSITES_SHARED_SECRET" => "change-me"
    }.each do |k, v|
      lines << "#{k}=#{v}"
    end
    File.write(path, (File.exist?(path) ? File.read(path) + "\n" : "") + lines.join("\n") + "\n")
    puts "Wrote placeholders to #{path}"
  end
end

namespace :telegram do
  desc "Set Telegram webhook to /api/v1/integrations/telegram with secret header"
  task set_webhook: :environment do
    require Rails.root.join("config/initializers/telegram")
    token = TELEGRAM_BOT_TOKEN
    secret = TELEGRAM_SECRET_TOKEN
    url = telegram_webhook_url
    abort "TELEGRAM_BOT_TOKEN is not set" if token.blank?
    abort "TELEGRAM_SECRET_TOKEN is not set" if secret.blank?
    api = URI("https://api.telegram.org/bot#{token}/setWebhook")
    payload = { url: url, secret_token: secret }
    http = Net::HTTP.new(api.host, api.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(api.request_uri, { "Content-Type" => "application/json" })
    req.body = JSON.generate(payload)
    res = http.request(req)
    puts "Response: #{res.code} #{res.body}"
  end

  desc "Delete Telegram webhook"
  task delete_webhook: :environment do
    require Rails.root.join("config/initializers/telegram")
    token = TELEGRAM_BOT_TOKEN
    abort "TELEGRAM_BOT_TOKEN is not set" if token.blank?
    api = URI("https://api.telegram.org/bot#{token}/deleteWebhook")
    http = Net::HTTP.new(api.host, api.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(api.request_uri)
    res = http.request(req)
    puts "Response: #{res.code} #{res.body}"
  end
end
