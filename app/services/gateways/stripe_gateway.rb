module Gateways
  class StripeGateway < BaseGateway
    PROVIDER = "stripe".freeze

    # For this scaffold, we assume payment creation happens on Stripe Checkout and our app records a pending Payment
  def self.create_payment!(amount_cents:, currency:, task:, payable:, metadata: {})
      # If STRIPE_SECRET_KEY is set and metadata doesn't include an external ID, create a Checkout Session server-side
      external_id = metadata["checkout_session_id"].presence || metadata["payment_intent_id"].presence || metadata["stripe_id"].presence
      checkout_url = metadata["checkout_url"]

      pi_id = metadata["payment_intent_id"]
      cs_id = metadata["checkout_session_id"]

      if external_id.blank? && ENV["STRIPE_SECRET_KEY"].present?
        require "stripe"
        ::Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
        session = ::Stripe::Checkout::Session.create({
          mode: "payment",
          line_items: [
            {
              price_data: {
                currency: currency,
                product_data: { name: "Payment" },
                unit_amount: amount_cents
              },
              quantity: 1
            }
          ],
          success_url: metadata["success_url"].presence || "#{ENV["APP_BASE_URL"]}/pay/success",
          cancel_url: metadata["cancel_url"].presence || "#{ENV["APP_BASE_URL"]}/pay/cancel"
        })
        external_id = session.id
        checkout_url = session.url
        cs_id = session.id
        pi_id = session.payment_intent if session.respond_to?(:payment_intent)
      end

      Payment.create!(
        provider: PROVIDER,
        external_id: external_id,
        amount_cents: amount_cents,
        currency: currency,
        task: task,
        payable: payable,
        payment_url: checkout_url,
        metadata: metadata,
        gateway_status: "pending",
        checkout_session_id: cs_id,
        payment_intent_id: pi_id,
        category: :service_fee,
        payment_type: :per_task
      )
    end

    # Verify Stripe signature and update Payment based on event type
    # Headers: 'Stripe-Signature'
    def self.process_webhook!(payload:, headers: {})
      secret = ENV["STRIPE_WEBHOOK_SECRET"].to_s
      sig = headers["Stripe-Signature"].to_s
      raw = headers["__raw_body__"].to_s

      raise "Missing Stripe webhook secret" if secret.blank?
      raise "Missing Stripe-Signature" if sig.blank?
      verify_stripe_signature!(secret: secret, signature_header: sig, payload: raw)

      event = JSON.parse(payload.is_a?(String) ? payload : payload.to_json) rescue {}
      type = event["type"].to_s
      data_object = event.dig("data", "object") || {}

      # Derive our external_id mapping: prefer payment_intent/checkout_session id
      external_id = data_object["payment_intent"].presence || data_object["id"].presence
      payment = Payment.find_by(provider: PROVIDER, external_id: external_id)
      # Sync commonly needed identifiers when available
      if payment
        updates = {}
        updates[:charge_id] = data_object["charge"] if data_object["charge"].present?
        updates[:payment_intent_id] = data_object["payment_intent"] if data_object["payment_intent"].present?
        updates[:checkout_session_id] = data_object["id"] if type.start_with?("checkout.session")
        # Stripe customer id
        updates[:stripe_customer_id] = data_object["customer"] if data_object["customer"].present?
        if type.start_with?("charge.refund") || type == "charge.refunded"
          # In real Stripe, refund amount can be in event.data.object.amount_refunded
          if data_object["amount_refunded"]
            updates[:refunded_amount_cents] = data_object["amount_refunded"].to_i
          end
          updates[:refund_reason] = data_object["reason"] if data_object["reason"].present?
          # Refund object may be embedded differently; try to capture refund id/status/balance tx
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
      when "payment_intent.succeeded", "checkout.session.completed", "charge.succeeded"
        payment&.update!(gateway_status: "succeeded")
      when "payment_intent.payment_failed", "charge.failed"
        payment&.update!(gateway_status: "failed")
      when "charge.refunded", "charge.refund.updated"
        if payment
          payment.update!(gateway_status: "refunded")
          # Create or update Refund record
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
    def self.refund!(payment:, amount_cents: nil, reason: nil)
      require "stripe"
      ::Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
      charge = payment.charge_id
      raise "Missing charge_id" if charge.blank?
      params = { charge: charge }
      params[:amount] = amount_cents if amount_cents
      params[:reason] = reason if reason
  refund = ::Stripe::Refund.create(params)
  payment.update!(gateway_status: "refunded", refunded_amount_cents: refund.amount, refund_reason: refund.reason,
          refund_id: refund.id, refund_status: refund.status, refund_balance_transaction_id: (refund.balance_transaction.is_a?(Hash) ? refund.balance_transaction.id : refund.balance_transaction), refunded_at: Time.at(refund.created))
  # Persist Refund model
  payment.refunds.create!(provider: PROVIDER, refund_id: refund.id, amount_cents: refund.amount, currency: refund.currency,
          reason: refund.reason, status: refund.status, balance_transaction_id: (refund.balance_transaction.is_a?(Hash) ? refund.balance_transaction.id : refund.balance_transaction), raw: refund.to_hash, occurred_at: Time.at(refund.created))
  refund
    end

    def self.capture!(payment:)
      require "stripe"
      ::Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
      intent = payment.payment_intent_id
      raise "Missing payment_intent_id" if intent.blank?
      ::Stripe::PaymentIntent.capture(intent)
      payment.update!(gateway_status: "succeeded")
    end

    def self.cancel!(payment:)
      require "stripe"
      ::Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
      intent = payment.payment_intent_id
      raise "Missing payment_intent_id" if intent.blank?
      ::Stripe::PaymentIntent.cancel(intent)
      payment.update!(gateway_status: "canceled")
    end

    def self.sync!(payment:)
      require "stripe"
      ::Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
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
                                   else payment.gateway_status end
      end
      payment.update!(updates) if updates.any?
      payment
    end

    # Minimal verification: Stripe spec uses a signed header with a timestamp and one or more signatures
    # Here, we compute v1 signature as HMAC-SHA256(secret, "t=timestamp.payload") and compare against the header
    def self.verify_stripe_signature!(secret:, signature_header:, payload:)
      elements = signature_header.split(",")
      ts = elements.find { |e| e.start_with?("t=") }&.split("=", 2)&.last
      v1 = elements.find { |e| e.start_with?("v1=") }&.split("=", 2)&.last
      raise "Invalid Stripe signature header" if ts.blank? || v1.blank?

      signed_payload = "t=#{ts}.#{payload}"
      computed = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      unless ActiveSupport::SecurityUtils.secure_compare(computed, v1)
        raise "Invalid Stripe signature"
      end
      true
    end
  end
end
