# frozen_string_literal: true

require "set"

class CarrierPayoutSync
  def self.call(task: nil, carrier: nil, task_id: nil, carrier_id: nil, purge: false)
    new(
      task_id: task&.id || task_id,
      carrier_id: carrier&.id || carrier_id,
      purge: purge
    ).call
  end

  def initialize(task_id: nil, carrier_id: nil, purge: false)
    @task_id = task_id
    @carrier_id = carrier_id
    @purge = purge
  end

  def call
    grouped = group_payments
    grouped.each do |(carrier_id, task_id), payments|
      upsert_payout(carrier_id, task_id, payments)
    end
    cleanup_orphans(grouped.keys)
  end

  private

  attr_reader :task_id, :carrier_id

  def group_payments
    groups = Hash.new { |hash, key| hash[key] = [] }
    payments_relation.find_each(batch_size: 200) do |payment|
      groups[[ payment.payable_id, payment.task_id ]] << payment
    end
    groups
  end

  def payments_relation
    scope = Payment
      .where(payable_type: "Carrier")
      .where.not(task_id: nil)
    scope = scope.where(payable_id: carrier_id) if carrier_id.present?
    scope = scope.where(task_id: task_id) if task_id.present?
    scope
  end

  def upsert_payout(carrier_id_from_payment, task_id_from_payment, payments)
    task = Task.find_by(id: task_id_from_payment)
    return if task.nil?

    carrier_id_for_task = task.carrier_id || carrier_id_from_payment
    return if carrier_id_for_task.blank?

    payout = CarrierPayout.find_or_initialize_by(
      carrier_id: carrier_id_for_task,
      task_id: task.id
    )

    payout.amount_cents = payments.sum { |payment| payment.amount_cents.to_i }
    payout.currency = currency_for(payments, payout)
    payout.status = derive_status(payments)
    payout.due_at = derive_due_at(payments, task)
    payout.paid_at = derive_paid_at(payments)
    payout.metadata = build_metadata(payout, payments)

    payout.save! if payout.changed?
  end

  def currency_for(payments, payout)
    payments.map(&:currency).compact.first.presence || payout.currency || "USD"
  end

  def derive_status(payments)
    statuses = payments.map { |payment| payment.gateway_status.to_s }
    return "disputed" if statuses.any? { |status| %w[refunded failed canceled].include?(status) }
    return "paid" if statuses.any? { |status| status == "succeeded" }
    return "scheduled" if statuses.any? { |status| status == "pending" }

    "pending"
  end

  def derive_due_at(payments, task)
    explicit_dates = payments.map(&:interval_end).compact
    return explicit_dates.min if explicit_dates.any?

    task.delivery_time || payments.map(&:created_at).compact.min
  end

  def derive_paid_at(payments)
    paid_payment = payments.select { |payment| payment.gateway_status == "succeeded" }
                            .max_by(&:updated_at)
    paid_payment&.updated_at
  end

  def build_metadata(payout, payments)
    existing = payout.metadata || {}
    payment_statuses = payments.each_with_object({}) do |payment, memo|
      memo[payment.id.to_s] = payment.gateway_status
    end

    existing.merge(
      "payment_ids" => payments.map(&:id),
      "payment_gateway_statuses" => payment_statuses,
      "source" => "payments",
      "synced_at" => Time.current.iso8601
    )
  end

  def cleanup_orphans(processed_keys)
    return unless should_cleanup?

    key_set = processed_keys.to_set
    scope = CarrierPayout.all
    scope = scope.where(carrier_id: carrier_id) if carrier_id.present?
    scope = scope.where(task_id: task_id) if task_id.present?

    scope.find_each do |payout|
      key = [ payout.carrier_id, payout.task_id ]
      next if key_set.include?(key)

      payout.destroy!
    end
  end

  def should_cleanup?
    purge? || scoped?
  end

  def purge?
    @purge
  end

  def scoped?
    task_id.present? || carrier_id.present?
  end
end
