require "application_system_test_case"
require "securerandom"

class DeliveriesClientValidationTest < ApplicationSystemTestCase
  setup do
    cleanup_records
    build_fixtures
  end

  test "submit button enables when form inputs valid" do
    authenticate_as(@manager)

    visit new_delivery_path

    submit = find_button("Create Delivery", disabled: :all)
    assert submit.disabled?, "expected submit to be disabled before selections"

    select @sender.full_name, from: "Sender / Lawyer"
    select @courier.full_name, from: "Courier"
    select @recipient.full_name, from: "Recipient"

    assert eventually_enabled?(submit), "expected submit to enable after valid selections"
  end

  test "missing required selection keeps submit disabled and displays inline message" do
    authenticate_as(@manager)

    visit new_delivery_path

    submit = find_button("Create Delivery", disabled: :all)
    select @sender.full_name, from: "Sender / Lawyer"
    select @recipient.full_name, from: "Recipient"

    # Do not pick a courier; expect field to highlight and button to remain disabled
    blur_field("Courier")

    assert submit.disabled?, "expected submit to remain disabled without courier"
    assert_text "Please choose a courier."
  end

  private

  def eventually_enabled?(button)
    Capybara.using_wait_time(3) do
      loop do
        return true unless button.disabled?
        sleep 0.1
        button = find("form[data-controller='delivery-form'] button[data-delivery-form-target='submit']", disabled: :all)
      end
    end
  rescue Capybara::ExpectationNotMet
    false
  end

  def cleanup_records
    ActiveRecord::Base.connection.disable_referential_integrity do
      ProofUpload.delete_all
      CarrierPayout.delete_all
      CarrierRating.delete_all
      Delivery.delete_all
      CarrierMembership.delete_all
      Messenger.delete_all
      Carrier.delete_all
      Sender.delete_all
      Customer.delete_all
      User.delete_all
    end
  end

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
      role: :viewer,
      user_type: :sender,
      full_name: "Sender Primary"
    )

    @courier = User.create!(
      email: "courier-alt-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: :viewer,
      user_type: :courier,
      full_name: "Courier Alternate"
    )

    @recipient = User.create!(
      email: "recipient-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: :viewer,
      user_type: :recipient,
      full_name: "Recipient Primary"
    )
  end

  def blur_field(label)
    field = find_field(label)
    field.click
    field.send_keys(:tab)
  end
end
