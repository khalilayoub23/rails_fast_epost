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

  test "generates local invoice pdf when payment succeeds" do
    payment = Payment.create!(
      provider: "stripe",
      category: :service_fee,
      payment_type: :per_task,
      task: @task,
      payable: @task.customer,
      amount_cents: 12_500,
      currency: "USD",
      gateway_status: :succeeded,
      external_id: "INV-TEST-#{SecureRandom.hex(4)}"
    )

    TaskPdfPacketService.call(task: @task, trigger: :payment_succeeded, payment: payment)

    @task.reload
    assert @task.legal_files.attachments.any? { |attachment| attachment.filename.to_s.include?("-invoice-#{payment.id}.pdf") }
  end

  test "includes configured fields in invoice payload" do
    payment = Payment.create!(
      provider: "stripe",
      category: :service_fee,
      payment_type: :per_task,
      task: @task,
      payable: @task.customer,
      amount_cents: 12_500,
      currency: "USD",
      gateway_status: :succeeded,
      external_id: "INV-TEST-#{SecureRandom.hex(4)}"
    )

    captured_title = nil
    captured_sections = nil

    with_invoice_env(
      "INVOICE_ISSUER_NAME" => "Fast Epost Billing",
      "INVOICE_SUPPORT_EMAIL" => "billing@fast-epost.test",
      "INVOICE_PAYMENT_TERMS" => "Net 0",
      "INVOICE_FOOTER_NOTE" => "Thank you for your business.",
      "INVOICE_INCLUDE_INTERNAL_IDS" => "true"
    ) do
      PdfGeneratorService.stub :generate_simple_document, ->(title, sections, **_opts) do
        captured_title = title
        captured_sections = sections
        "stub-pdf"
      end do
        TaskPdfPacketService.call(task: @task, trigger: :payment_succeeded, payment: payment)
      end
    end

    assert_equal "Task Invoice", captured_title
    details = captured_sections.find { |section| section[:heading] == "Invoice Details" }
    from = captured_sections.find { |section| section[:heading] == "From" }
    notes = captured_sections.find { |section| section[:heading] == "Notes" }

    assert_includes details[:body], "Payment Terms: Net 0"
    assert_includes details[:body], "Task ID: #{@task.id}"
    assert_includes details[:body], "Payment ID: #{payment.id}"
    assert_includes from[:body], "Name: Fast Epost Billing"
    assert_includes notes[:body], "Support: billing@fast-epost.test"
    assert_includes notes[:body], "Thank you for your business."
  end

  private

  def with_invoice_env(values)
    previous = values.each_with_object({}) { |(key, _value), memo| memo[key] = ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each do |key, old_value|
      old_value.nil? ? ENV.delete(key) : ENV[key] = old_value
    end
  end
end
