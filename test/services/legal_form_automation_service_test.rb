require "test_helper"

class LegalFormAutomationServiceTest < ActiveSupport::TestCase
  setup do
    @task = tasks(:task_one)
    @task.update!(lawyer: lawyers(:lawyer_one))
    @payment = payments(:one)
    @payment.update!(task: @task, gateway_status: :succeeded)
    documents(:carrier_one_signature)
  end

  test "creates or updates form with populated payload and backfills template schema" do
    template = form_templates(:one)
    template.update!(schema: {})

    @form = LegalFormAutomationService.call(task: @task, payment: @payment)

    assert_not_nil @form
    assert @form.persisted?

    template.reload
    assert_includes template.schema.fetch("fields"), { "name" => "task_barcode", "label" => "Task Barcode", "type" => "text" }

    assert_equal @task, @form.task
    assert_equal @task.customer, @form.customer
    assert_equal @task.target, @form.address
    assert_match(%r{https?://[^/]+/form_templates/\d+}, @form.form_default_url)

    payload = @form.data
    assert_equal @task.barcode, payload["task_barcode"]
    assert_equal @task.priority, payload["task_priority"]
    assert_equal documents(:carrier_one_signature).signature, payload["carrier_signature"]
    assert_equal "true", payload["carrier_signature_captured"]
    assert_equal @payment.external_id, payload["payment_reference"]
    assert_equal @payment.amount_cents, payload["payment_amount_cents"]
  end

  test "updates existing form instead of duplicating" do
    first_run = LegalFormAutomationService.call(task: @task, payment: @payment)
    @task.update!(target: "Updated Target Address")

    assert_no_difference("Form.count") do
      @form = LegalFormAutomationService.call(task: @task, payment: @payment)
    end

    assert_equal first_run.id, @form.id
    assert_equal "Updated Target Address", @form.address
    assert_equal "Updated Target Address", @form.data["delivery_target"]
  end

  test "returns nil when task missing lawyer" do
    @task.update!(lawyer: nil)

    assert_no_difference([ "Form.count", "FormTemplate.count" ]) do
      assert_nil LegalFormAutomationService.call(task: @task, payment: @payment)
    end
  end
end
