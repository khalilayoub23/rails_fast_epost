module Api
  module V1
    module Integrations
      class InstagramController < BaseWebhookController
        def verify
          token = ENV["META_VERIFY_TOKEN"]
          return forbidden if token.blank?

          if params["hub.mode"] == "subscribe" && verify_header_token!(token, params["hub.verify_token"])
            render plain: params["hub.challenge"], status: :ok
          else
            forbidden
          end
        end

        def receive
          secret = ENV["META_APP_SECRET"]
          return forbidden if secret.blank?
          return forbidden unless verify_meta_signature!(secret)

          Integrations::InstagramService.process(json_body, headers: request.headers.to_h, signature_valid: true)
          ok
        end
      end
    end
  end
end
