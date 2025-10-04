module Api
  module V1
    module Payments
      class PaymentIntentsController < ApplicationController
        protect_from_forgery with: :null_session
        skip_before_action :verify_authenticity_token

        def create
          provider = params[:provider].to_s.presence || "local"
          amount_cents = params[:amount_cents].to_i
          currency = params[:currency].to_s.presence || "USD"
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
          provider = params[:provider]
          raw = request.raw_post.to_s
          headers = request.headers.to_h.merge("__raw_body__" => raw)
          payload = JSON.parse(raw) rescue {}

          case provider
          when "local"
            intent = Gateways::LocalGateway.process_webhook!(payload: payload, headers: headers)
            render json: { ok: true, id: intent&.id }
          else
            render json: { error: "Unsupported provider" }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
