require "test_helper"

class ProofUploadTest < ActiveSupport::TestCase

  setup do
    @task = tasks(:one)
    @user = users(:operations_manager)
  end

  test "saves with defaults when file attached" do
    proof = ProofUpload.new(task: @task, uploaded_by: @user)
    proof.file.attach(io: file_fixture("proof.txt").open, filename: "proof.txt", content_type: "text/plain")

    assert proof.save, -> { proof.errors.full_messages.to_sentence }
    assert_equal @task.carrier, proof.carrier
    assert_not_nil proof.recorded_at
    assert_equal "photo", proof.category
  end

  test "requires file attachment" do
    proof = ProofUpload.new(task: @task, uploaded_by: @user, recorded_at: Time.current)

    assert_not proof.valid?
    assert_includes proof.errors[:file], "can't be blank"
  end

  test "rejects unsupported category" do
    proof = ProofUpload.new(task: @task, uploaded_by: @user, recorded_at: Time.current)
    proof.file.attach(io: file_fixture("proof.txt").open, filename: "proof.txt", content_type: "text/plain")

    assert_raises(ArgumentError) { proof.category = "invalid" }
  end
end
