module Api
  module V1
    module Integrations
      class WebsitesController < BaseWebhookController
        def receive
          shared = ENV["WEBSITES_SHARED_SECRET"]
          header = request.headers["X-Website-Secret"].presence || request.headers["X-Websites-Secret"].presence
          return forbidden unless shared.present?
          valid = verify_header_token!(shared, header)
          return forbidden unless valid

          Integrations::WebsitesService.process(json_body, headers: request.headers.to_h, signature_valid: valid)
          ok
        end
      end
    end
  end
end
