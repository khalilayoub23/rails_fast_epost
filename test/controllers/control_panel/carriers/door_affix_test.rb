require "test_helper"

class ControlPanel::Carriers::DoorAffixTest < ActionDispatch::IntegrationTest
  setup do
    @carrier = users(:carrier_one) if defined?(users)
    @carrier ||= User.where(user_type: :carrier).first
    @task = Task.create!(
      customer: customers(:one),
      carrier: carriers(:one),
      task_type: "delivery_and_pickup",
      package_type: "box",
      start: "A",
      target: "B",
      delivery_time: 1.day.from_now,
      status: :failed,
      failed_attempts: Task::MAX_FAILED_ATTEMPTS,
      barcode: "AFFIX123",
      door_affix_authorized: true
    )

    sign_in @carrier
  end

  test "door affix requires door and address photos" do
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9YlCPz8AAAAASUVORK5CYII=")
    door = Rack::Test::UploadedFile.new(StringIO.new(png), "image/png", original_filename: "door.png")
    address = Rack::Test::UploadedFile.new(StringIO.new(png), "image/png", original_filename: "address.png")

    assert_difference("ProofUpload.count", 2) do
      post door_affix_control_panel_carriers_task_path(@task), params: {
        proof_uploads: [
          { file: door, category: "door_affix_photo" },
          { file: address, category: "door_affix_address" }
        ]
      }
    end

    assert_redirected_to control_panel_carriers_dashboard_path
    @task.reload
    assert @task.door_affix_completed?
    assert @task.door_affix_completed_at.present?
  end
end
