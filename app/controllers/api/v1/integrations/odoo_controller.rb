module Api
  module V1
    module Integrations
      class OdooController < BaseWebhookController
        # POST /api/v1/integrations/odoo
        # Odoo CRM webhook receiver (Free/Open Source)
        def receive
          # Odoo doesn't have built-in signature verification
          # Recommended: Use IP whitelist or API key authentication
          api_key = request.headers["X-Odoo-Api-Key"].presence
          configured_key = ENV["ODOO_API_KEY"]

          return forbidden if configured_key.blank?
          return forbidden unless api_key == configured_key

          ::Integrations::OdooService.process(json_body, headers: request.headers.to_h)
          ok
        end
      end
    end
  end
end
