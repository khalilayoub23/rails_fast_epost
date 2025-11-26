module ControlPanel
  module Lawyers
    class DashboardsController < ControlPanel::BaseController
      before_action :require_operations_role!
      before_action :set_lawyer

      def show
        if @lawyer.nil?
          @empty_state = true
          return
        end

        tasks = @lawyer.tasks.includes(:carrier, :customer)
        @caseload = build_caseload(tasks)
        @compliance_rate = calculate_compliance_rate(tasks)
        @pending_clearances = tasks.where(status: [ Task.statuses[:pending], Task.statuses[:failed] ]).order(updated_at: :desc).limit(6)
        @recent_clearances = tasks.where(status: Task.statuses[:delivered]).order(delivery_time: :desc).limit(6)
        @control_panel_title = "#{@lawyer.display_name} · Lawyer Panel"
      end

      private

      def set_lawyer
        @lawyer_scope = accessible_lawyers
        @lawyer = resolve_panel_entity(@lawyer_scope, session_key: :lawyer_context_id, param_key: :lawyer_id)
      end

      def build_caseload(tasks)
        counts = tasks.group(:status).count
        active = counts.fetch(Task.statuses[:pending], 0) + counts.fetch(Task.statuses[:in_transit], 0)
        delivered = counts.fetch(Task.statuses[:delivered], 0)
        investigative = counts.fetch(Task.statuses[:failed], 0)

        {
          total: tasks.count,
          active: active,
          delivered: delivered,
          investigative: investigative
        }
      end

      def calculate_compliance_rate(tasks)
        total = tasks.count
        return 0.0 if total.zero?

        delivered = tasks.where(status: Task.statuses[:delivered]).count
        ((delivered.to_f / total) * 100).round(1)
      end
    end
  end
end
