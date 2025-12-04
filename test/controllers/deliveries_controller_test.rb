require "test_helper"

class DeliveriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manager = users(:manager)
    sign_in @manager
    @delivery = build_delivery!(case_number: "CASE-TABLE-001")
  end

  test "index renders list" do
    get deliveries_path
    assert_response :success
    assert_includes response.body, @delivery.case_number
  end

  test "create delivery enqueues pdf processing" do
    params = {
      sender_id: @delivery.sender_id,
      courier_id: @delivery.courier_id,
      recipient_id: @delivery.recipient_id,
      case_number: "CASE-#{SecureRandom.alphanumeric(6).upcase}",
      notes: "Signed via test"
    }

    assert_enqueued_with(job: ProcessDeliveryPdfJob, queue: "pdf_processing") do
      assert_difference("Delivery.count", 1) do
        post deliveries_path, params: { delivery: params }
      end
    end

    created = Delivery.order(created_at: :desc).first
    assert_redirected_to delivery_path(created)
  end

  test "recipient cannot create delivery due to pundit policy" do
    recipient = users(:recipient_user)
    sign_out @manager
    sign_in recipient

    params = {
      sender_id: @delivery.sender_id,
      courier_id: @delivery.courier_id,
      recipient_id: @delivery.recipient_id,
      case_number: "CASE-#{SecureRandom.alphanumeric(6).upcase}",
      notes: "Attempted via unauthorized recipient"
    }

    assert_no_difference("Delivery.count") do
      post deliveries_path, params: { delivery: params }
    end

    assert_redirected_to root_path
    assert_match(/not authorized/i, flash[:alert])
  end
end
