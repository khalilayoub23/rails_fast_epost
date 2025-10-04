class Refund < ApplicationRecord
  belongs_to :payment

  validates :provider, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Turbo Streams: broadcast dashboard KPI updates when refunds change
  after_create_commit :broadcast_kpi_update
  after_update_commit :broadcast_kpi_update
  after_destroy_commit :broadcast_kpi_update

  private

  def broadcast_kpi_update
    ApplicationController.renderer # ensure renderer is loaded
    broadcast_replace_later_to "dashboard", target: "dashboard_kpis", partial: "dashboard/kpis"
  end
end
