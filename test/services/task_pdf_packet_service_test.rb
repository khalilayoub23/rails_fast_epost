require "test_helper"

class TaskPdfPacketServiceTest < ActiveSupport::TestCase
  setup do
    @task = tasks(:task_one)
    @task.update!(lawyer: lawyers(:lawyer_one))
    @task.legal_files.purge
  end

  test "generates template-based pdf documents for lifecycle trigger" do
    TaskPdfPacketService.call(task: @task, trigger: :created)

    @task.reload
    assert @task.legal_files.attached?
    assert @task.legal_files.attachments.any? { |attachment| attachment.filename.to_s.include?("task-#{@task.barcode}-created-template") }
  end

  test "generates completion certificate when delivered" do
    TaskPdfPacketService.call(task: @task, trigger: :delivered)

    @task.reload
    assert @task.legal_files.attachments.any? { |attachment| attachment.filename.to_s.include?("completion-certificate") }
  end
end
