module ControlPanel
  module Carriers
    class DashboardsController < BaseController
      def show
        @carrier = current_carrier_context
        @board_columns = build_board(@carrier)
        @payout_metrics = build_payout_metrics(@carrier)
        @recent_payouts = @carrier.carrier_payouts.order(updated_at: :desc).limit(8)
        @events = TrackingEvent
          .joins(:task)
          .where(tasks: { carrier_id: @carrier.id })
          .order(occurred_at: :desc)
          .limit(10)
      end

      private

      def build_board(carrier)
        tasks = carrier.tasks.includes(:customer, proof_uploads: { file_attachment: :blob })
        awaiting_payout = tasks.delivered
          .left_outer_joins(:carrier_payout)
          .where(carrier_payouts: { status: [ CarrierPayout.statuses[:pending], CarrierPayout.statuses[:scheduled], CarrierPayout.statuses[:disputed], nil ] })

        {
          "New" => tasks.pending.order(created_at: :desc),
          "In Transit" => tasks.in_transit.order(updated_at: :desc),
          "Failed / Needs Attention" => tasks.failed.order(updated_at: :desc),
          "Awaiting Payout" => awaiting_payout.order(updated_at: :desc)
        }
      end

      def build_payout_metrics(carrier)
        payouts = carrier.carrier_payouts
        outstanding = payouts.outstanding
        cleared = payouts.cleared

        {
          outstanding_amount_cents: outstanding.sum(:amount_cents),
          outstanding_count: outstanding.count,
          cleared_amount_cents: cleared.sum(:amount_cents),
          cleared_count: cleared.count,
          next_due_at: outstanding.minimum(:due_at)
        }
      end
    end
  end
end
