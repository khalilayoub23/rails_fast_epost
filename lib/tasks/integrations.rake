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
