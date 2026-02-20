module Api
  module V1
    module Integrations
      class BaseWebhookController < ApplicationController
        protect_from_forgery with: :null_session
        skip_before_action :verify_authenticity_token
        skip_before_action :authenticate_user!

        private

        def json_body
          JSON.parse(request_body.presence || "{}")
        rescue JSON::ParserError
          {}
        end

        def request_body
          @request_body ||= request.raw_post.to_s
        end

        def ok
          render json: { status: "ok" }
        end

        def forbidden
          head :forbidden
        end

        def secure_compare(a, b)
          left = a.to_s
          right = b.to_s
          return false if left.blank? || right.blank?
          return false unless left.bytesize == right.bytesize

          ActiveSupport::SecurityUtils.secure_compare(left, right)
        end

        # Meta (Facebook/Instagram/WhatsApp) signature verification
        # Header example: X-Hub-Signature-256: sha256=abcdef...
        def verify_meta_signature!(secret)
          header = request.headers["X-Hub-Signature-256"].to_s
          return false if secret.blank? || header.blank?

          scheme, their_sig = header.split("=", 2)
          return false unless scheme == "sha256" && their_sig.present?

          our_sig = OpenSSL::HMAC.hexdigest("SHA256", secret, request_body)
          secure_compare(our_sig, their_sig)
        end

        # Generic HMAC-SHA256 Base64 verification (commonly used by TikTok)
        # Compare Base64.strict_encode64(HMAC-SHA256(secret, body)) with header
        def verify_hmac_base64!(secret, header_value)
          return false if secret.blank? || header_value.blank?

          computed = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, request_body))
          secure_compare(computed, header_value)
        end

        def verify_header_token!(expected, provided)
          return false if expected.blank? || provided.blank?
          secure_compare(expected, provided)
        end
      end
    end
  end
end
