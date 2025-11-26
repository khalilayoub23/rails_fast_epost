module ControlPanel
  module Senders
    class DashboardsController < ControlPanel::BaseController
      before_action :require_operations_role!
      before_action :set_sender

      def show
        if @sender.nil?
          @empty_state = true
          return
        end

        tasks = @sender.tasks.includes(:carrier)
        payments = Payment.where(task_id: tasks.select(:id))

        @task_stats = build_task_stats(tasks)
        @spend_summary = build_spend_summary(payments)
        @avg_delivery_hours = average_delivery_hours(tasks)
        @recent_tasks = tasks.order(updated_at: :desc).limit(10)
        @issue_log = tasks.merge(Task.failed).order(updated_at: :desc).limit(5)
        @carrier_mix = carrier_mix(tasks)

        @control_panel_title = "#{@sender.display_name} · Sender Panel"
      end

      private

      def set_sender
        @sender_scope = accessible_senders
        @sender = resolve_panel_entity(@sender_scope, session_key: :sender_context_id, param_key: :sender_id)
      end

      def build_task_stats(tasks)
        counts = tasks.group(:status).count
        {
          total: tasks.count,
          pending: counts.fetch(Task.statuses[:pending], 0),
          in_transit: counts.fetch(Task.statuses[:in_transit], 0),
          delivered: counts.fetch(Task.statuses[:delivered], 0),
          failed: counts.fetch(Task.statuses[:failed], 0)
        }
      end

      def build_spend_summary(payments)
        total = payments.sum(:amount_cents).to_i
        pending = payments.where(gateway_status: %w[pending created]).sum(:amount_cents).to_i
        succeeded = payments.where(gateway_status: :succeeded).sum(:amount_cents).to_i

        {
          total: total,
          pending: pending,
          succeeded: succeeded
        }
      end

      def average_delivery_hours(tasks)
        rows = tasks.where(status: Task.statuses[:delivered]).where.not(delivery_time: nil).pluck(:created_at, :delivery_time)
        return nil if rows.empty?

        total_hours = rows.sum { |created_at, delivered_at| ((delivered_at - created_at) / 1.hour).round(2) }
        (total_hours / rows.size.to_f).round(1)
      end

      def carrier_mix(tasks)
        counts = tasks.group(:carrier_id).count
        carrier_ids = counts.keys.compact
        carriers = Carrier.where(id: carrier_ids).index_by(&:id)
        counts.map do |carrier_id, count|
          carrier_name = carriers[carrier_id]&.name || "Unassigned"
          { name: carrier_name, count: count }
        end.sort_by { |entry| -entry[:count] }
      end
    end
  end
end
