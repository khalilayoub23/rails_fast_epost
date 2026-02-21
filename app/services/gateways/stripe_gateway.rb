module Gateways
  class StripeGateway < BaseGateway
    PROVIDER = "stripe".freeze

    class << self
      # For this scaffold, we assume payment creation happens on Stripe Checkout and our app records a pending Payment
      def create_payment!(amount_cents:, currency:, task:, payable:, metadata: {}, category: :service_fee, payment_type: :per_task)
        data = normalize_metadata(metadata)
        external_id = data["checkout_session_id"].presence || data["payment_intent_id"].presence || data["stripe_id"].presence
        checkout_url = data["checkout_url"]
        pi_id = data["payment_intent_id"]
        cs_id = data["checkout_session_id"]

        if external_id.blank?
          secret = stripe_secret_key
          simulate = ENV.fetch("STRIPE_SIMULATE", "false") == "true"

          if secret.present? && !simulate
            begin
              configure_stripe!(secret)
              line_items = data["stripe_line_items"].presence
              line_items = [
                {
                  price_data: {
                    currency: currency,
                    product_data: { name: "Payment" },
                    unit_amount: amount_cents
                  },
                  quantity: 1
                }
              ] if line_items.blank?
              session = ::Stripe::Checkout::Session.create(
                mode: "payment",
                line_items: line_items,
                success_url: default_success_url(data),
                cancel_url: default_cancel_url(data)
              )
              external_id = session.id
              checkout_url = session.url
              cs_id = session.id
              pi_id = session.payment_intent if session.respond_to?(:payment_intent)
            rescue ::Stripe::AuthenticationError
              if Rails.env.development? || Rails.env.test?
                external_id = "sim_cs_#{SecureRandom.hex(10)}"
                cs_id = external_id
                pi_id = "sim_pi_#{SecureRandom.hex(10)}"
                success_template = default_success_url(data)
                checkout_url = success_template.gsub("{CHECKOUT_SESSION_ID}", external_id)
              else
                raise
              end
            end
          elsif Rails.env.development? || Rails.env.test?
            # Simulate Stripe in development/test if keys are missing or explicit simulation is enabled
            external_id = "sim_cs_#{SecureRandom.hex(10)}"
            cs_id = external_id
            pi_id = "sim_pi_#{SecureRandom.hex(10)}"

            # Construct a local success URL
            success_template = default_success_url(data)
            checkout_url = success_template.gsub("{CHECKOUT_SESSION_ID}", external_id)
          end
        end

        data["checkout_session_id"] ||= cs_id if cs_id.present?
        data["payment_intent_id"] ||= pi_id if pi_id.present?
        data["checkout_url"] ||= checkout_url if checkout_url.present?

        Payment.create!(
          provider: PROVIDER,
          external_id: external_id,
          amount_cents: amount_cents,
          currency: currency,
          task: task,
          payable: payable,
          payment_url: checkout_url,
          metadata: data,
          gateway_status: "pending",
          checkout_session_id: cs_id,
          payment_intent_id: pi_id,
          category: category,
          payment_type: payment_type
        )
      end

      # Verify Stripe signature and update Payment based on event type
      # Headers: 'Stripe-Signature'
      def process_webhook!(payload:, headers: {})
        secret = ENV["STRIPE_WEBHOOK_SECRET"].to_s
        sig = headers["Stripe-Signature"].to_s
        raw = headers["__raw_body__"].to_s

        # In production we require a secret. In dev/test, allow blank secrets so
        # local runs and tests can still exercise the webhook flow.
        raise "Missing Stripe webhook secret" if secret.blank? && Rails.env.production?
        raise "Missing Stripe-Signature" if sig.blank?
        verify_stripe_signature!(secret: secret, signature_header: sig, payload: raw) if secret.present?

        event = JSON.parse(payload.is_a?(String) ? payload : payload.to_json) rescue {}
        type = event["type"].to_s
        data_object = event.dig("data", "object") || {}

        payment = resolve_payment_from_event(data_object: data_object, event_type: type)

        if payment
          updates = {}
          updates[:charge_id] = data_object["charge"] if data_object["charge"].present?
          updates[:payment_intent_id] = data_object["payment_intent"] if data_object["payment_intent"].present?
          updates[:checkout_session_id] = data_object["id"] if type.start_with?("checkout.session")
          updates[:stripe_customer_id] = data_object["customer"] if data_object["customer"].present?
          if type.start_with?("charge.refund") || type == "charge.refunded"
            if data_object["amount_refunded"]
              updates[:refunded_amount_cents] = data_object["amount_refunded"].to_i
            end
            updates[:refund_reason] = data_object["reason"] if data_object["reason"].present?
            updates[:refund_id] = data_object["id"] if data_object["object"] == "refund"
            updates[:refund_status] = data_object["status"] if data_object["status"].present?
            if (bt = data_object["balance_transaction"]).present?
              updates[:refund_balance_transaction_id] = bt.is_a?(Hash) ? bt["id"] : bt
            end
            updates[:refunded_at] = Time.at(data_object["created"]) if data_object["created"].present?
          end
          payment.update_columns(updates) if updates.any?
        end

        case type
        when "payment_intent.succeeded", "checkout.session.completed", "checkout.session.async_payment_succeeded", "charge.succeeded"
          if payment
            payment.update!(gateway_status: "succeeded")
            materialize_task_if_needed(payment)
          end
        when "payment_intent.payment_failed", "checkout.session.async_payment_failed", "charge.failed"
          payment&.update!(gateway_status: "failed")
        when "payment_intent.processing"
          payment&.update!(gateway_status: "pending")
        when "payment_intent.canceled"
          payment&.update!(gateway_status: "canceled")
        when "charge.refunded", "charge.refund.updated"
          if payment
            payment.update!(gateway_status: "refunded")
            ref_id = data_object["id"] if data_object["object"] == "refund"
            amt_val = data_object["amount_refunded"] || data_object["amount"]
            attrs = {
              payment: payment,
              provider: PROVIDER,
              refund_id: ref_id,
              amount_cents: (amt_val.nil? ? nil : amt_val.to_i),
              currency: data_object["currency"],
              reason: data_object["reason"],
              status: data_object["status"],
              balance_transaction_id: (data_object["balance_transaction"].is_a?(Hash) ? data_object["balance_transaction"]["id"] : data_object["balance_transaction"]),
              raw: data_object,
              occurred_at: (Time.at(data_object["created"]) rescue Time.current)
            }
            if ref_id.present?
              Refund.find_or_initialize_by(provider: PROVIDER, refund_id: ref_id).update!(attrs)
            else
              payment.refunds.create!(attrs)
            end
          end
        when "checkout.session.expired"
          payment&.update!(gateway_status: "canceled")
        end

        payment
      end

      # Management helpers
      def refund!(payment:, amount_cents: nil, reason: nil)
        configure_stripe!
        charge = payment.charge_id
        raise "Missing charge_id" if charge.blank?

        params = { charge: charge }
        params[:amount] = amount_cents if amount_cents
        params[:reason] = reason if reason

        refund = ::Stripe::Refund.create(params)
        payment.update!(
          gateway_status: "refunded",
          refunded_amount_cents: refund.amount,
          refund_reason: refund.reason,
          refund_id: refund.id,
          refund_status: refund.status,
          refund_balance_transaction_id: (refund.balance_transaction.is_a?(Hash) ? refund.balance_transaction.id : refund.balance_transaction),
          refunded_at: Time.at(refund.created)
        )

        payment.refunds.create!(
          provider: PROVIDER,
          refund_id: refund.id,
          amount_cents: refund.amount,
          currency: refund.currency,
          reason: refund.reason,
          status: refund.status,
          balance_transaction_id: (refund.balance_transaction.is_a?(Hash) ? refund.balance_transaction.id : refund.balance_transaction),
          raw: refund.to_hash,
          occurred_at: Time.at(refund.created)
        )

        refund
      end

      def capture!(payment:)
        configure_stripe!
        intent = payment.payment_intent_id
        raise "Missing payment_intent_id" if intent.blank?
        ::Stripe::PaymentIntent.capture(intent)
        payment.update!(gateway_status: "succeeded")
      end

      def cancel!(payment:)
        configure_stripe!
        intent = payment.payment_intent_id
        raise "Missing payment_intent_id" if intent.blank?
        ::Stripe::PaymentIntent.cancel(intent)
        payment.update!(gateway_status: "canceled")
      end

      def sync!(payment:)
        if payment.checkout_session_id.to_s.start_with?("sim_cs_")
          payment.update!(gateway_status: "succeeded")
          return payment
        end

        configure_stripe!
        if payment.checkout_session_id.present?
          cs = ::Stripe::Checkout::Session.retrieve(payment.checkout_session_id)
          pi = cs.payment_intent ? ::Stripe::PaymentIntent.retrieve(cs.payment_intent) : nil
        elsif payment.payment_intent_id.present?
          pi = ::Stripe::PaymentIntent.retrieve(payment.payment_intent_id)
        end

        updates = {}
        if pi
          updates[:payment_intent_id] = pi.id
          updates[:charge_id] = pi.charges&.data&.first&.id if pi.respond_to?(:charges)
          updates[:gateway_status] = case pi.status
          when "succeeded" then "succeeded"
          when "canceled" then "canceled"
          when "requires_payment_method", "requires_confirmation", "processing" then "pending"
          else payment.gateway_status
          end
        end

        payment.update!(updates) if updates.any?
        payment
      end

      # Minimal verification: Stripe spec uses a signed header with a timestamp and one or more signatures
      # Here, we compute v1 signature as HMAC-SHA256(secret, "t=timestamp.payload") and compare against the header
      def verify_stripe_signature!(secret:, signature_header:, payload:)
        elements = signature_header.split(",")
        ts = elements.find { |e| e.start_with?("t=") }&.split("=", 2)&.last
        signatures = elements.filter_map { |e| e.start_with?("v1=") ? e.split("=", 2).last : nil }
        raise "Invalid Stripe signature header" if ts.blank? || signatures.blank?

        timestamp = Integer(ts)
        tolerance = 300
        raise "Expired Stripe signature" if (Time.now.to_i - timestamp).abs > tolerance

        signed_payload = "t=#{ts}.#{payload}"
        computed = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        matched = signatures.any? { |sig| signature_matches?(computed, sig) }
        unless matched
          raise "Invalid Stripe signature"
        end
        true
      rescue ArgumentError
        raise "Invalid Stripe signature header"
      end

      def signature_matches?(expected, provided)
        left = expected.to_s
        right = provided.to_s
        return false if left.blank? || right.blank?
        return false unless left.bytesize == right.bytesize

        ActiveSupport::SecurityUtils.secure_compare(left, right)
      end

      private

        def materialize_task_if_needed(payment)
          task_ids = Array(payment.metadata.to_h["task_ids"]).map(&:to_i)
          if task_ids.present?
            CartPaymentMaterializer.new(payment: payment).call
            return
          end

          return if payment.task_id.present?
          TaskPaymentMaterializer.new(payment: payment).call
        rescue => e
          Rails.logger.error("[StripeGateway] Failed to materialize task: #{e.message}")
        end

        def normalize_metadata(metadata)
        return {} if metadata.nil?
        hash = if metadata.respond_to?(:to_unsafe_h)
                 metadata.to_unsafe_h
        elsif metadata.respond_to?(:to_h)
                 metadata.to_h
        elsif metadata.is_a?(Hash)
                 metadata
        else
                 {}
        end
        hash.deep_stringify_keys
      end

      def stripe_secret_key
        Rails.configuration.x.try(:stripe).try(:secret_key).presence
      end

      def configure_stripe!(secret = stripe_secret_key)
        raise "Stripe secret key not configured" if secret.blank?
        require "stripe"
        ::Stripe.api_key = secret
        secret
      end

      def default_success_url(metadata)
        metadata["success_url"].presence || "#{app_base_url}/pay/success"
      end

      def default_cancel_url(metadata)
        metadata["cancel_url"].presence || "#{app_base_url}/pay/cancel"
      end

      def app_base_url
        ENV["APP_BASE_URL"].presence || "http://localhost:3000"
      end

      def resolve_payment_from_event(data_object:, event_type:)
        payment_intent_id = data_object["payment_intent"].presence
        checkout_session_id = if event_type.start_with?("checkout.session")
                                data_object["id"].presence
        else
                                data_object["checkout_session"].presence
        end

        charge_id = case data_object["object"]
        when "charge"
                      data_object["id"].presence
        when "refund"
                      data_object["charge"].presence
        else
                      data_object["charge"].presence
        end

        external_ids = [ payment_intent_id, checkout_session_id, data_object["id"].presence ].compact.uniq
        payment = Payment.where(provider: PROVIDER, external_id: external_ids).first if external_ids.any?
        payment ||= Payment.find_by(provider: PROVIDER, checkout_session_id: checkout_session_id) if checkout_session_id.present?
        payment ||= Payment.find_by(provider: PROVIDER, payment_intent_id: payment_intent_id) if payment_intent_id.present?
        payment ||= Payment.find_by(provider: PROVIDER, charge_id: charge_id) if charge_id.present?
        payment
      end
    end
  end
end
