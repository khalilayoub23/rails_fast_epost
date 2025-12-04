require "test_helper"

class DeliveriesFormErrorHandlingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @manager = User.create!(
      email: "manager-form-test@example.com",
      password: "password123",
      role: :manager,
      user_type: :sender,
      full_name: "Manager User"
    )

    @sender = User.create!(
      email: "sender-form-test@example.com",
      password: "password123",
      role: :viewer,
      user_type: :sender,
      full_name: "Sender Person"
    )

    @courier = User.create!(
      email: "courier-form-test@example.com",
      password: "password123",
      role: :viewer,
      user_type: :courier,
      full_name: "Courier Person"
    )

    @recipient = User.create!(
      email: "recipient-form-test@example.com",
      password: "password123",
      role: :viewer,
      user_type: :recipient,
      full_name: "Recipient Person"
    )

    @existing_delivery = Delivery.create!(
      sender: @sender,
      courier: @courier,
      recipient: @recipient,
      notes: "Seed delivery for case number collision"
    )
  end

  test "inline association errors render with field highlighting" do
    sign_in @manager, scope: :user

    post deliveries_path, params: {
      delivery: {
        sender_id: "",
        courier_id: "",
        recipient_id: "",
        case_number: "",
        notes: ""
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "border-red-500", "Expected error border class to be present"
    assert_includes response.body, "delivery_sender_id", "Expected sender select to be rendered"
    assert_includes response.body, "must exist", "Expected association error message to render inline"
  end

  test "duplicate case number shows inline error styling" do
    sign_in @manager, scope: :user

    post deliveries_path, params: {
      delivery: {
        sender_id: @sender.id,
        courier_id: @courier.id,
        recipient_id: @recipient.id,
        case_number: @existing_delivery.case_number,
        notes: "Duplicate case"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "border-red-500", "Expected error border class to be present"
    assert_includes response.body, "has already been taken", "Expected duplicate case number message"
  end
end
