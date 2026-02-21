module Api
  module V1
    module Payments
      class PaymentIntentsController < ApplicationController
        ALLOWED_PROVIDERS = %w[local].freeze
        ALLOWED_CURRENCIES = %w[USD EUR ILS].freeze

        protect_from_forgery with: :null_session
        skip_before_action :verify_authenticity_token

        def create
          provider = params[:provider].to_s.downcase.presence || "local"
          return render json: { error: "Unsupported provider" }, status: :unprocessable_entity unless ALLOWED_PROVIDERS.include?(provider)

          amount_cents = params[:amount_cents].to_i
          return render json: { error: "Invalid amount" }, status: :unprocessable_entity unless amount_cents.positive?

          currency = params[:currency].to_s.upcase.presence || "USD"
          return render json: { error: "Unsupported currency" }, status: :unprocessable_entity unless ALLOWED_CURRENCIES.include?(currency)

          task = Task.find_by(id: params[:task_id])
          customer = Customer.find_by(id: params[:customer_id])
          metadata = params[:metadata].is_a?(ActionController::Parameters) ? params[:metadata].to_unsafe_h : (params[:metadata] || {})

          intent = case provider
          when "local"
                     Gateways::LocalGateway.create_intent!(amount_cents: amount_cents, currency: currency, task: task, customer: customer, metadata: metadata)
          else
                     render json: { error: "Unsupported provider" }, status: :unprocessable_entity and return
          end

          render json: intent, status: :created
        end

        def webhook
          provider = params[:provider].to_s.downcase
          return render json: { error: "Unsupported provider" }, status: :unprocessable_entity unless ALLOWED_PROVIDERS.include?(provider)

          raw = request.raw_post.to_s
          headers = request.headers.to_h.merge("__raw_body__" => raw)
          payload = JSON.parse(raw)

          case provider
          when "local"
            local_secret = ENV["LOCALPAY_APP_SECRET"].to_s
            header_secret = request.headers["X-Localpay-Secret"].to_s
            return render json: { error: "Webhook secret not configured" }, status: :forbidden if local_secret.blank?
            return render json: { error: "Unauthorized" }, status: :forbidden unless secret_matches?(local_secret, header_secret)

            intent = Gateways::LocalGateway.process_webhook!(payload: payload, headers: headers)
            render json: { ok: true, id: intent&.id }
          else
            render json: { error: "Unsupported provider" }, status: :unprocessable_entity
          end
        rescue JSON::ParserError
          render json: { error: "Invalid JSON payload" }, status: :bad_request
        end

        private

        def secret_matches?(expected, provided)
          left = expected.to_s
          right = provided.to_s
          return false if left.blank? || right.blank?
          return false unless left.bytesize == right.bytesize

          ActiveSupport::SecurityUtils.secure_compare(left, right)
        end
      end
    end
  end
end
