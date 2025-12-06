require "test_helper"

class SignaturesControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @delivery = build_delivery!(case_number: "CASE-SIGN-001")
    @recipient = @delivery.recipient
    sign_in @recipient
  end

  test "recipient can capture signature via turbo stream" do
    data_uri = fixture_signature_data_uri

    assert_difference("SignatureEvent.count", 1) do
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
        post delivery_signatures_path(@delivery, format: :turbo_stream),
          params: { signature_role: "recipient", signature_data: data_uri }
      end
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    @delivery.reload
    assert @delivery.signature_completed?("recipient")
    assert @delivery.recipient_signature_copy.attached?
    assert_includes response.body, dom_id(@delivery, :progress)
    assert_includes response.body, dom_id(@delivery, "recipient_signature_card")
  end

  test "unauthenticated recipient can sign with valid token" do
    sign_out @recipient
    data_uri = fixture_signature_data_uri
    token = SignatureToken.generate(delivery: @delivery, user: @recipient, role: "recipient")

    assert_difference("SignatureEvent.count", 1) do
      post delivery_signatures_path(@delivery, format: :json),
        params: { signature_role: "recipient", signature_data: data_uri, token: token }
    end

    assert_response :success
    @delivery.reload
    assert @delivery.signature_completed?("recipient")
  end
end
