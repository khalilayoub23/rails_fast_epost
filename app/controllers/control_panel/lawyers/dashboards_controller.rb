module ControlPanel
  module Lawyers
    class DashboardsController < ControlPanel::BaseController
      skip_before_action :require_control_panel_access!, only: :show
      before_action :require_lawyer_panel_access!
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
        @recent_tasks = tasks.order(updated_at: :desc).limit(8)
        @tasks_count = tasks.count
        @control_panel_title = "#{@lawyer.display_name} · Lawyer Panel"
      end

      private

      def require_lawyer_panel_access!
        return if current_user&.admin? || current_user&.operations_manager? || current_user&.lawyer?

        message = t("messages.unauthorized", default: "You are not authorized to access this panel.")
        redirect_to(root_path, alert: message)
      end

      def accessible_lawyers
        return Lawyer.order(Arel.sql("LOWER(name)")) if current_user&.admin? || current_user&.operations_manager?

        if current_user&.lawyer?
          lawyer = Lawyer.find_by(email: current_user.email)
          return Lawyer.where(id: lawyer.id) if lawyer
        end

        Lawyer.none
      end

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
