module Api
  module V1
    module Integrations
      class TiktokController < BaseWebhookController
        def receive
          secret = ENV["TIKTOK_APP_SECRET"]
          header = request.headers["X-Tt-Signature"].presence ||
                   request.headers["X-Tiktok-Signature"].presence ||
                   request.headers["Tiktok-Signature"].presence

          return forbidden unless verify_hmac_base64!(secret, header)

          Integrations::TiktokService.process(json_body, headers: request.headers.to_h, signature_valid: true)
          ok
        end
      end
    end
  end
end
