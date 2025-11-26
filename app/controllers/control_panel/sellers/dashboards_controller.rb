module ControlPanel
  module Sellers
    class DashboardsController < ControlPanel::BaseController
      before_action :require_operations_role!
      before_action :set_seller

      def show
        if @seller.nil?
          @empty_state = true
          return
        end

        tasks = @seller.tasks.includes(:carrier)
        @order_metrics = build_order_metrics(tasks)
        @sla_breaches = sla_breaches(tasks)
        @top_products = top_package_types(tasks)
        @recent_orders = tasks.order(updated_at: :desc).limit(8)
        @control_panel_title = "#{@seller.display_name} · Seller Panel"
      end

      private

      def set_seller
        @seller_scope = accessible_sellers
        @seller = resolve_panel_entity(@seller_scope, session_key: :seller_context_id, param_key: :seller_id)
      end

      def build_order_metrics(tasks)
        counts = tasks.group(:status).count
        delivered = counts.fetch(Task.statuses[:delivered], 0)
        in_transit = counts.fetch(Task.statuses[:in_transit], 0)
        pending = counts.fetch(Task.statuses[:pending], 0)
        failed = counts.fetch(Task.statuses[:failed], 0)

        {
          delivered: delivered,
          in_transit: in_transit,
          pending: pending,
          failed: failed,
          total: tasks.count
        }
      end

      def sla_breaches(tasks)
        overdue = tasks.merge(Task.in_transit).where("delivery_time < ?", Time.current)
        failed = tasks.merge(Task.failed)
        overdue.or(failed).order(updated_at: :desc).limit(5)
      end

      def top_package_types(tasks)
        tasks.group(:package_type).order(Arel.sql("COUNT(*) DESC")).limit(5).count
      end
    end
  end
end
