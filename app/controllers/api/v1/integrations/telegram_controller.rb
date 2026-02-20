module Api
  module V1
    module Integrations
      class TelegramController < BaseWebhookController
        def receive
          secret = ENV["TELEGRAM_SECRET_TOKEN"]
          provided = request.headers["X-Telegram-Bot-Api-Secret-Token"]
          return forbidden unless verify_header_token!(secret, provided)

          Integrations::TelegramService.process(json_body, headers: request.headers.to_h, signature_valid: true)
          ok
        end
      end
    end
  end
end
