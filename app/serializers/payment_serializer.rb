class PaymentSerializer
  FIELDS = %i[
    id provider external_id gateway_status amount_cents currency payment_url
    task_id payable_type payable_id metadata created_at updated_at
    stripe_customer_id payment_intent_id checkout_session_id charge_id refunded_amount_cents refund_reason
    refund_id refund_status refund_balance_transaction_id refunded_at
  ].freeze

  def self.render(record)
    return [] if record.is_a?(Array) && record.empty?
    if record.is_a?(Enumerable)
      record.map { |r| render_one(r) }
    else
      render_one(record)
    end
  end

  def self.render_one(record)
    payload = record.as_json(only: FIELDS)
    if record.respond_to?(:refunds)
      payload["refunds"] = record.refunds.order(occurred_at: :desc, created_at: :desc).map do |r|
        {
          id: r.id,
          refund_id: r.refund_id,
          provider: r.provider,
          amount_cents: r.amount_cents,
          currency: r.currency,
          reason: r.reason,
          status: r.status,
          balance_transaction_id: r.balance_transaction_id,
          occurred_at: r.occurred_at,
          created_at: r.created_at,
          updated_at: r.updated_at
        }
      end
    end
    payload
  end
end
