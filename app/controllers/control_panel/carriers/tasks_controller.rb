module ControlPanel
  module Carriers
    class TasksController < BaseController
      def update_status
        task = carrier_tasks.find(params[:id])
        next_status = params.require(:task).fetch(:status)
        note = params[:task][:note].presence

        case next_status
        when "in_transit"
          task.ship! if task.may_ship?
        when "delivered"
          task.deliver! if task.may_deliver?
        when "failed"
          failure_reason = note || "Carrier reported delivery failure"
          task.mark_failed_with_note!(failure_reason)
        else
          raise ArgumentError, "Unsupported status"
        end

        task.record_tracking_event!(
          title: "Status updated by carrier",
          event_type: "status",
          status: task.status,
          description: note,
          metadata: { carrier_user_id: current_user.id }
        )

        respond_to do |format|
          format.html { redirect_back fallback_location: control_panel_carriers_dashboard_path, notice: "Task updated" }
          format.turbo_stream { redirect_to control_panel_carriers_dashboard_path, notice: "Task updated" }
        end
      rescue StandardError => e
        respond_to do |format|
          format.html { redirect_back fallback_location: control_panel_carriers_dashboard_path, alert: e.message }
          format.turbo_stream { redirect_to control_panel_carriers_dashboard_path, alert: e.message }
        end
      end

      def flag_issue
        task = carrier_tasks.find(params[:id])
        content = params.require(:issue).fetch(:content)
        task.remarks.create!(remarkable: current_user, content: content)
        task.record_tracking_event!(
          title: "Issue flagged by carrier",
          event_type: "issue",
          status: task.status,
          description: content,
          metadata: { carrier_user_id: current_user.id }
        )

        respond_to do |format|
          format.html { redirect_back fallback_location: control_panel_carriers_dashboard_path, notice: "Issue reported" }
          format.turbo_stream { redirect_to control_panel_carriers_dashboard_path, notice: "Issue reported" }
        end
      rescue StandardError => e
        respond_to do |format|
          format.html { redirect_back fallback_location: control_panel_carriers_dashboard_path, alert: e.message }
          format.turbo_stream { redirect_to control_panel_carriers_dashboard_path, alert: e.message }
        end
      end

      private

      def carrier_tasks
        current_carrier_context.tasks
      end
    end
  end
end
