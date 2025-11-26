module ControlPanel
  module Operations
    class DashboardsController < ControlPanel::BaseController
      before_action :require_operations_role!

      def show
        @control_panel_title = "Operations Control Room"
        @kpis = build_kpis
        @carrier_leaderboard = Carrier.order(average_overall_rating: :desc).limit(5)
        @payout_alerts = CarrierPayout.outstanding.order(Arel.sql("COALESCE(due_at, NOW()) ASC")).limit(5)
        @late_tasks = Task.in_transit.order(delivery_time: :asc).limit(5)
        @incident_feed = TrackingEvent.order(occurred_at: :desc).limit(8)
      end

      private

      def build_kpis
        active_scope = Task.where(status: [ Task.statuses[:pending], Task.statuses[:in_transit] ])
        delayed_scope = Task.in_transit.where("delivery_time < ?", 12.hours.ago)
        failed_scope = Task.failed
        outstanding_cents = CarrierPayout.outstanding.sum(:amount_cents)

        {
          active_tasks: active_scope.count,
          delayed_tasks: delayed_scope.count,
          failed_tasks: failed_scope.count,
          outstanding_payouts_cents: outstanding_cents,
          carriers_online: Carrier.count,
          active_senders: Sender.active.count
        }
      end
    end
  end
end
