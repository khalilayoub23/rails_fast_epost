module Api
  module V1
    class PaymentsController < ApplicationController
      ALLOWED_PROVIDERS = %w[local stripe].freeze
      ALLOWED_CURRENCIES = %w[USD EUR ILS].freeze

      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!
      before_action :authenticate_payment_management!, only: %i[refund capture cancel sync]

      # POST /api/v1/payments
      def create
        provider = params[:provider].to_s.presence || "local"
        return render json: { error: "Unsupported provider" }, status: :unprocessable_entity unless ALLOWED_PROVIDERS.include?(provider)

        amount_cents = params[:amount_cents].to_i
        return render json: { error: "Amount must be greater than zero" }, status: :unprocessable_entity if amount_cents <= 0

        currency = params[:currency].to_s.upcase.presence || "USD"
        return render json: { error: "Unsupported currency" }, status: :unprocessable_entity unless ALLOWED_CURRENCIES.include?(currency)

        task = Task.find_by(id: params[:task_id])
        payable = find_payable
        metadata = params[:metadata].is_a?(ActionController::Parameters) ? params[:metadata].to_unsafe_h : (params[:metadata] || {})

        payment = case provider
        when "local"
          Gateways::LocalGateway.create_payment!(amount_cents: amount_cents, currency: currency, task: task, payable: payable, metadata: metadata)
        when "stripe"
          Gateways::StripeGateway.create_payment!(amount_cents: amount_cents, currency: currency, task: task, payable: payable, metadata: metadata)
        else
          render json: { error: "Unsupported provider" }, status: :unprocessable_entity and return
        end

        render json: PaymentSerializer.render(payment), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # POST /api/v1/payments/:id/refund
      def refund
        payment = Payment.find(params[:id])
        return render json: { error: "Unsupported provider" }, status: :unprocessable_entity unless payment.provider == "stripe"
        amount_cents = params[:amount_cents]&.to_i
        reason = params[:reason]
        Gateways::StripeGateway.refund!(payment: payment, amount_cents: amount_cents, reason: reason)
        render json: PaymentSerializer.render(payment.reload)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/payments/:id/capture
      def capture
        payment = Payment.find(params[:id])
        return render json: { error: "Unsupported provider" }, status: :unprocessable_entity unless payment.provider == "stripe"
        Gateways::StripeGateway.capture!(payment: payment)
        render json: PaymentSerializer.render(payment.reload)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/payments/:id/cancel
      def cancel
        payment = Payment.find(params[:id])
        return render json: { error: "Unsupported provider" }, status: :unprocessable_entity unless payment.provider == "stripe"
        Gateways::StripeGateway.cancel!(payment: payment)
        render json: PaymentSerializer.render(payment.reload)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/payments/:id/sync
      def sync
        payment = Payment.find(params[:id])
        return render json: { error: "Unsupported provider" }, status: :unprocessable_entity unless payment.provider == "stripe"
        Gateways::StripeGateway.sync!(payment: payment)
        render json: PaymentSerializer.render(payment.reload)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/payments/:provider/webhook
      def webhook
        provider = params[:provider]
        return render json: { error: "Unsupported provider" }, status: :unprocessable_entity unless ALLOWED_PROVIDERS.include?(provider)

        raw = request.raw_post.to_s
        # Normalize headers for gateways: rack prefixes custom headers with HTTP_
        headers = request.headers.to_h
        headers["X-Signature"] ||= headers["HTTP_X_SIGNATURE"]
        headers["Stripe-Signature"] ||= headers["HTTP_STRIPE_SIGNATURE"]
        headers["__raw_body__"] = raw
        payload = JSON.parse(raw)

        case provider
        when "local"
          local_secret = ENV["LOCALPAY_APP_SECRET"].to_s
          return render json: { error: "Webhook secret not configured" }, status: :forbidden if local_secret.blank?

          payment = Gateways::LocalGateway.process_webhook!(payload: payload, headers: headers)
          render json: { ok: true, id: payment&.id }
        when "stripe"
          # Allow blank webhook secret in non-production (tests/dev) to let gateway
          # handle verification when appropriate. Only enforce in production.
          return render json: { error: "Webhook secret not configured" }, status: :forbidden if ENV["STRIPE_WEBHOOK_SECRET"].blank? && Rails.env.production?

          payment = Gateways::StripeGateway.process_webhook!(payload: raw, headers: headers)
          render json: { ok: true, id: payment&.id }
        else
          render json: { error: "Unsupported provider" }, status: :unprocessable_entity
        end
      rescue JSON::ParserError
        render json: { error: "Invalid JSON payload" }, status: :bad_request
      end

      private

      def find_payable
        type = safe_string(params[:payable_type])
        id = params[:payable_id]
        return nil if type.blank? || id.blank?

        # Whitelist allowed payable types
        allowed_types = %w[Customer Carrier Task Order Subscription]
        return nil unless allowed_types.include?(type)

        type.constantize.find_by(id: id)
      rescue NameError
        nil
      end

      def safe_string(value)
        v = value.to_s
        return nil if v.size > 100
        return nil unless v.match?(/\A[A-Za-z][A-Za-z0-9_]*(::[A-Za-z][A-Za-z0-9_]*)*\z/)
        v
      end

      def authenticate_payment_management!
        return if current_user&.admin? || current_user&.manager? || current_user&.support_agent?

        shared_secret = ENV["LOCALPAY_APP_SECRET"].to_s
        header_secret = request.headers["X-Internal-Api-Secret"].to_s.presence || request.headers["X-Localpay-Secret"].to_s.presence

        if shared_secret.present? && header_secret.present? && ActiveSupport::SecurityUtils.secure_compare(shared_secret, header_secret)
          return
        end

        render json: { error: "Unauthorized" }, status: :forbidden
      end
    end
  end
end
