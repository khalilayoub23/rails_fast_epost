module ControlPanel
  module Carriers
    class TasksController < BaseController
      def update_status
        task = carrier_tasks.find(params[:id])
        next_status = params.require(:task).fetch(:status)
        note = params[:task][:note].presence

        location = extract_location(params[:task])

        case next_status
        when "in_transit"
          task.ship! if task.may_ship?
        when "delivered"
          task.deliver! if task.may_deliver?
          persist_success_location(task, location)
        when "failed"
          failure_reason = note || "Carrier reported delivery failure"
          task.mark_failed_with_note!(failure_reason, location: location)
        else
          raise ArgumentError, "Unsupported status"
        end

        task.record_tracking_event!(
          title: "Status updated by carrier",
          event_type: "status",
          status: task.status,
          description: note,
          metadata: { carrier_user_id: current_user.id, location: location }.compact
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

      def door_affix
        task = carrier_tasks.find(params[:id])
        raise Pundit::NotAuthorizedError, "Door affix not authorized" unless task.door_affix_authorized?
        raise StandardError, "Door affix available only after failed attempts" if task.failed_attempts.to_i < Task::MAX_FAILED_ATTEMPTS

        uploads = Array(params[:proof_uploads])
        door_photo = uploads.find { |u| u[:category] == "door_affix_photo" }
        address_photo = uploads.find { |u| u[:category] == "door_affix_address" }
        raise StandardError, "Door photo required" unless door_photo&.dig(:file).present?
        raise StandardError, "Address photo required" unless address_photo&.dig(:file).present?

        ProofUpload.transaction do
          uploads.each do |upload_params|
            next unless upload_params[:file].present?

            task.proof_uploads.create!(
              file: upload_params[:file],
              notes: upload_params[:notes],
              category: upload_params[:category] || "door_affix_extra",
              recorded_at: Time.current,
              uploaded_by: current_user,
              carrier: current_carrier_context
            )
          end

          task.update!(door_affix_completed: true, door_affix_completed_at: Time.current)
          task.record_tracking_event!(
            title: "Door affix completed",
            event_type: "door_affix",
            status: task.status,
            description: "Carrier posted documents on door",
            metadata: { carrier_user_id: current_user.id, attempt_number: task.failed_attempts }
          )
        end

        redirect_back fallback_location: control_panel_carriers_dashboard_path, notice: "Door affix recorded"
      rescue StandardError => e
        redirect_back fallback_location: control_panel_carriers_dashboard_path, alert: e.message
      end

      private

      def carrier_tasks
        current_carrier_context.tasks
      end

      def persist_success_location(task, location)
        return if location.blank?

        task.update!(
          last_success_lat: location[:lat],
          last_success_lng: location[:lng],
          last_success_accuracy: location[:accuracy]
        )
      end

      def extract_location(task_params)
        return nil unless task_params

        lat = task_params[:lat] || task_params[:latitude]
        lng = task_params[:lng] || task_params[:longitude]
        accuracy = task_params[:accuracy]

        return nil if lat.blank? || lng.blank?

        {
          lat: lat.to_f,
          lng: lng.to_f,
          accuracy: accuracy&.to_f
        }.compact
      end
    end
  end
end
