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
          location = extract_location(params[:task])

          case next_status
          when "in_transit"
            task.ship! if task.may_ship?
          when "delivered"
            task.deliver! if task.may_deliver?
            persist_success_location(task, location)
          when "failed"
            task.mark_failed_with_note!(note.presence || "Carrier reported failure", location: location)
          else
            return render json: { error: "Unsupported status" }, status: :unprocessable_entity
          end

          task.record_tracking_event!(
            title: "Status updated via API",
            event_type: "status",
            status: task.status,
            description: note,
            metadata: { carrier_user_id: current_user.id, channel: "api", location: location }.compact
          )

          render json: task_payload(task)
        rescue StandardError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def door_affix
          task = carrier.tasks.find(params[:id])
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

              validate_upload!(upload_params[:file])

              task.proof_uploads.create!(
                file: upload_params[:file],
                notes: upload_params[:notes],
                category: upload_params[:category] || "door_affix_extra",
                recorded_at: Time.current,
                uploaded_by: current_user,
                carrier: carrier
              )
            end

            task.update!(door_affix_completed: true, door_affix_completed_at: Time.current)
            task.record_tracking_event!(
              title: "Door affix completed",
              event_type: "door_affix",
              status: task.status,
              description: "Carrier posted documents on door",
              metadata: { carrier_user_id: current_user.id, channel: "api", attempt_number: task.failed_attempts }
            )
          end

          render json: task_payload(task), status: :created
        rescue StandardError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def validate_upload!(file)
          allowed_types = %w[image/jpeg image/png application/pdf]
          max_size_bytes = 5.megabytes

          content_type = file.content_type if file.respond_to?(:content_type)
          size_bytes = file.size if file.respond_to?(:size)

          raise StandardError, "Unsupported file type" unless allowed_types.include?(content_type)
          raise StandardError, "File too large" if size_bytes.present? && size_bytes > max_size_bytes
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
            accuracy: accuracy&.to_f,
            channel: "api"
          }.compact
        end

        def persist_success_location(task, location)
          return if location.blank?

          task.update!(
            last_success_lat: location[:lat],
            last_success_lng: location[:lng],
            last_success_accuracy: location[:accuracy]
          )
        end

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
