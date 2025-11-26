module Api
  module V1
    module Carriers
      class TasksController < BaseController
        def index
          tasks = carrier.tasks.order(updated_at: :desc)
          render json: tasks.map { |task| task_payload(task) }
        end

        def update
          task = carrier.tasks.find(params[:id])
          next_status = params.require(:task).fetch(:status)
          note = params[:task][:note]

          case next_status
          when "in_transit"
            task.ship! if task.may_ship?
          when "delivered"
            task.deliver! if task.may_deliver?
          when "failed"
            task.mark_failed_with_note!(note.presence || "Carrier reported failure")
          else
            return render json: { error: "Unsupported status" }, status: :unprocessable_entity
          end

          task.record_tracking_event!(
            title: "Status updated via API",
            event_type: "status",
            status: task.status,
            description: note,
            metadata: { carrier_user_id: current_user.id, channel: "api" }
          )

          render json: task_payload(task)
        rescue StandardError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def task_payload(task)
          {
            id: task.id,
            barcode: task.barcode,
            status: task.status,
            priority: task.priority,
            title: task.title,
            pickup: task.start,
            dropoff: task.target,
            customer: {
              id: task.customer_id,
              name: task.customer&.name
            },
            updated_at: task.updated_at,
            failure_note: task.last_failure_note
          }
        end
      end
    end
  end
end
