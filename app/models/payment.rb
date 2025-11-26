class Payment < ApplicationRecord
  has_many :payments_tasks
  has_many :tasks, through: :payments_tasks
  has_many :refunds, dependent: :destroy
  belongs_to :payable, polymorphic: true
  # Associate payment to a primary task — fixtures reference tasks by label (task: one)
  # The payments table already has a task_id column and a foreign key to tasks.
  belongs_to :task, optional: true

  # Define category enum (positional syntax)
  enum :category, { service_fee: 0, delivery_fee: 1, insurance: 2, penalty: 3 }

  # Define payment_type enum (positional syntax)
  enum :payment_type, { per_task: 0, lump_sum: 1 }

  validates :category, presence: true
  validates :payment_type, presence: true
  # interval_start and interval_end are optional datetime fields; no extra validation required

  # Gateway fields
  enum :gateway_status, { created: "created", pending: "pending", succeeded: "succeeded", failed: "failed", canceled: "canceled", refunded: "refunded" }, prefix: true
  validates :external_id, uniqueness: { scope: :provider }, allow_nil: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def mark_succeeded!
    update!(gateway_status: "succeeded")
  end

  def mark_failed!
    update!(gateway_status: "failed")
  end

  # Turbo Streams: broadcast list updates and dashboard KPI refreshes
  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_destroy_commit :broadcast_destroyed
  after_commit :generate_legal_forms_if_needed, if: :legal_form_trigger?
  after_commit :sync_carrier_payout_if_needed, if: :carrier_payable?, on: [ :create, :update ]
  after_destroy_commit :sync_carrier_payout_if_needed, if: :carrier_payable?

  private

  def legal_form_trigger?
    saved_change_to_gateway_status? && gateway_status == "succeeded" && task&.lawyer.present?
  end

  def generate_legal_forms_if_needed
    LegalFormAutomationService.call(task: task, payment: self)
  rescue => e
    Rails.logger.error("[Payment #{id}] Failed to automate legal forms: #{e.message}")
  end

  def broadcast_created
    ApplicationController.renderer # ensure renderer is loaded
    broadcast_prepend_later_to "payments", target: "payments", partial: "payments/payment", locals: { payment: self }
    broadcast_replace_later_to "dashboard", target: "dashboard_kpis", partial: "dashboard/kpis"
  end

  def broadcast_updated
    broadcast_replace_later_to "payments", target: ActionView::RecordIdentifier.dom_id(self), partial: "payments/payment", locals: { payment: self }
    broadcast_replace_later_to "dashboard", target: "dashboard_kpis", partial: "dashboard/kpis"
  end

  def broadcast_destroyed
    broadcast_remove_to "payments", target: ActionView::RecordIdentifier.dom_id(self)
    broadcast_replace_later_to "dashboard", target: "dashboard_kpis", partial: "dashboard/kpis"
  end

  def carrier_payable?
    payable_type == "Carrier" && payable_id.present? && task_id.present?
  end

  def sync_carrier_payout_if_needed
    CarrierPayoutSync.call(task_id: task_id, carrier_id: carrier_id_for_payout)
  rescue => e
    Rails.logger.error("[Payment #{id}] Failed to sync carrier payout: #{e.message}")
  end

  def carrier_id_for_payout
    if payable_type == "Carrier" && payable_id.present?
      payable_id
    else
      task&.carrier_id
    end
  end
end
