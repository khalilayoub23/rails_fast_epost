require "test_helper"

class ControlPanel::Carriers::ProofUploadsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess
  setup do
    @user = users(:operations_manager)
    sign_in @user
    @task = tasks(:one)
  end

  test "creates proof upload with attachment" do
    file = fixture_file_upload("proof.txt", "text/plain")

    assert_difference("ProofUpload.count", 1) do
      post control_panel_carriers_task_proof_uploads_path(@task), params: {
        carrier_id: carriers(:one).id,
        proof_upload: {
          file: file,
          notes: "Left with concierge",
          category: "signature"
        }
      }
    end

    assert_redirected_to control_panel_carriers_dashboard_path
    assert_equal "Proof uploaded", flash[:notice]

    proof = ProofUpload.order(created_at: :desc).first
    assert_equal @user, proof.uploaded_by
    assert_equal @task, proof.task
    assert proof.file.attached?
  end

  test "destroys proof upload" do
    proof = proof_uploads(:delivered_photo)

    assert_difference("ProofUpload.count", -1) do
      delete control_panel_carriers_task_proof_upload_path(proof.task, proof), params: { carrier_id: carriers(:one).id }
    end

    assert_redirected_to control_panel_carriers_dashboard_path
    assert_equal "Proof removed", flash[:notice]
  end
end
