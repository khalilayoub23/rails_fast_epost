require "application_system_test_case"
require "securerandom"

class DeliveriesClientValidationTest < ApplicationSystemTestCase
  setup do
    build_fixtures
  end

  test "valid selections create a delivery" do
    authenticate_as(@manager)

    visit new_delivery_path


    select @sender.full_name, from: "Sender / Lawyer"
    select @courier.full_name, from: "Courier"
    select @recipient.full_name, from: "Recipient"

    submit_delivery_form

    assert_text "Delivery overview"
    assert_text "Requires 3 signatures"
  end

  test "missing required selection keeps user on form with validation message" do
    authenticate_as(@manager)

    visit new_delivery_path

    select @sender.full_name, from: "Sender / Lawyer"
    select @recipient.full_name, from: "Recipient"

    submit_delivery_form

    assert_current_path new_delivery_path
    assert_text "Create Delivery"
    assert_selector "form[action='#{deliveries_path}']"
  end

  private

  def build_fixtures
    @manager = User.create!(
      email: "manager-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: :manager,
      user_type: :sender,
      full_name: "Manager User"
    )

    @sender = User.create!(
      email: "sender-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: :sender,
      user_type: :sender,
      full_name: "Sender Primary"
    )

    @courier = User.create!(
      email: "courier-alt-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: :carrier_staff,
      user_type: :courier,
      full_name: "Courier Alternate"
    )

    @recipient = User.create!(
      email: "recipient-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: :sender,
      user_type: :recipient,
      full_name: "Recipient Primary"
    )
  end

  def submit_delivery_form
    page.execute_script("document.querySelector('form[data-controller=\"delivery-form\"]').requestSubmit()")
  end
end
