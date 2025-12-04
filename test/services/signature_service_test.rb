require "test_helper"

class SignatureServiceTest < ActiveSupport::TestCase
  setup do
    @delivery = build_delivery!(case_number: "CASE-SERVICE-001")
    @service = SignatureService.new(@delivery)
  end

  test "applies courier saved signature and logs event" do
    courier = @delivery.courier

    assert_difference(["SignatureEvent.count", "@delivery.audit_logs.count"], +1) do
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
        @service.add_signature(role: :courier, signed_by_user: courier, ip_address: "8.8.8.8")
      end
    end

    @delivery.reload
    assert @delivery.signature_completed?("courier"), "expected courier signature to be completed"
    assert @delivery.courier_signature_copy.attached?
    event = @delivery.signature_events.order(created_at: :desc).first
    assert_equal "courier", event.role
    assert_equal "signature_added", event.action
  end
end
