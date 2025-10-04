module Api
  module V1
    module Integrations
      class HubspotController < BaseWebhookController
        # POST only; HubSpot CRM webhooks
        def receive
          shared = ENV["HUBSPOT_APP_SECRET"]
          header = request.headers["X-HubSpot-Signature"].presence
          valid = shared.present? ? verify_hmac_base64!(shared, header) : true
          return forbidden unless valid

          Integrations::HubspotService.process(json_body, headers: request.headers.to_h, signature_valid: valid)
          ok
        end
      end
    end
  end
end
