module ControlPanel
  module Carriers
    class ProofUploadsController < BaseController
      before_action :set_task

      def create
        @proof_upload = @task.proof_uploads.new(proof_upload_params)
        @proof_upload.uploaded_by = current_user
        @proof_upload.carrier = current_carrier_context

        if @proof_upload.save
          redirect_back fallback_location: control_panel_carriers_dashboard_path, notice: "Proof uploaded"
        else
          redirect_back fallback_location: control_panel_carriers_dashboard_path, alert: @proof_upload.errors.full_messages.to_sentence
        end
      end

      def destroy
        proof = @task.proof_uploads.find(params[:id])
        proof.destroy!
        redirect_back fallback_location: control_panel_carriers_dashboard_path, notice: "Proof removed"
      end

      private

      def set_task
        @task = current_carrier_context.tasks.find(params[:task_id])
      end

      def proof_upload_params
        params.require(:proof_upload).permit(:file, :notes, :category, :recorded_at)
      end
    end
  end
end
