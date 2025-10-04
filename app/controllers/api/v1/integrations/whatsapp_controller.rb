module Api
  module V1
    module Integrations
      class WhatsappController < BaseWebhookController
        # Meta Webhook verification (GET)
        def verify
          token = ENV["META_VERIFY_TOKEN"]
          if params["hub.mode"] == "subscribe" && params["hub.verify_token"] == token
            render plain: params["hub.challenge"], status: :ok
          else
            forbidden
          end
        end

        # Receive webhook (POST)
        def receive
          secret = ENV["META_APP_SECRET"]
          return forbidden unless verify_meta_signature!(secret)

          Integrations::WhatsappService.process(json_body, headers: request.headers.to_h, signature_valid: true)
          ok
        end
      end
    end
  end
end
