require "test_helper"

class TasksHelperTest < ActionView::TestCase
  include TasksHelper

  FakeFile = Struct.new(:filename)

  test "grouped_task_legal_files groups and orders lifecycle files" do
    files = [
      FakeFile.new("task-ABC123-payment-succeeded-template-1.pdf"),
      FakeFile.new("task-ABC123-created-summary.pdf"),
      FakeFile.new("task-ABC123-in-transit-template-2.pdf"),
      FakeFile.new("task-ABC123-completion-certificate.pdf")
    ]

    grouped = grouped_task_legal_files(files)

    assert_equal [ :created, :status_updates, :payment, :completion ], grouped.map(&:first)
    assert_equal "Task Created", grouped[0][1]
    assert_equal "Status Updates", grouped[1][1]
    assert_equal "Payment", grouped[2][1]
    assert_equal "Completion", grouped[3][1]
  end

  test "grouped_task_legal_files places unknown files in other documents" do
    files = [ FakeFile.new("manual-customer-attachment.pdf") ]

    grouped = grouped_task_legal_files(files)

    assert_equal [ :other ], grouped.map(&:first)
    assert_equal "Other Documents", grouped.first[1]
    assert_equal 1, grouped.first[2].size
  end
end
