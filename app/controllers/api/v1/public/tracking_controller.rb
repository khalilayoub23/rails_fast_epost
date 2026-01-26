module Api
  module V1
    module Public
      class TrackingController < Api::V1::BaseController
        before_action :require_public_tracking_key!

        # GET /api/v1/public/track/:barcode
        def show
          barcode = params[:barcode].upcase.strip
          task = Task.find_by(barcode: barcode)

          if task
            render json: {
              success: true,
              data: {
                barcode: task.barcode,
                status: task.status,
                status_label: task.status&.titleize,
                package_type: task.package_type,
                delivery_time: task.delivery_time,
                pickup_address: format_address(task.pickup_address),
                delivery_address: format_address(task.delivery_address),
                carrier: {
                  id: task.carrier_id,
                  name: task.carrier&.name
                },
                created_at: task.created_at,
                updated_at: task.updated_at,
                estimated_delivery: task.delivery_time
              }
            }, status: :ok
          else
            render json: {
              success: false,
              error: "Tracking number not found",
              message: "The tracking number '#{params[:barcode]}' could not be found in our system."
            }, status: :not_found
          end
        rescue => e
          render json: {
            success: false,
            error: "Internal server error",
            message: e.message
          }, status: :internal_server_error
        end

        private

        def require_public_tracking_key!
          expected = ENV["PUBLIC_TRACKING_API_KEY"].to_s
          provided = request.headers["X-Public-Api-Key"].to_s

          return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, provided)

          render json: { success: false, error: "Unauthorized" }, status: :forbidden
        end

        def format_address(address)
          return nil if address.blank?

          {
            street: address["street"],
            city: address["city"],
            state: address["state"],
            country: address["country"],
            postal_code: address["postal_code"]
          }
        end
      end
    end
  end
end
