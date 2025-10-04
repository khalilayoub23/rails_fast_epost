module Api
  module V1
    module Integrations
      class FacebookController < BaseWebhookController
        def verify
          token = ENV["META_VERIFY_TOKEN"]
          if params["hub.mode"] == "subscribe" && params["hub.verify_token"] == token
            render plain: params["hub.challenge"], status: :ok
          else
            forbidden
          end
        end

        def receive
          secret = ENV["META_APP_SECRET"]
          return forbidden unless verify_meta_signature!(secret)

          Integrations::FacebookService.process(json_body, headers: request.headers.to_h, signature_valid: true)
          ok
        end
      end
    end
  end
end
