require "application_system_test_case"
require "securerandom"

class PaymentsUiTest < ApplicationSystemTestCase
  setup do
    cleanup_records
    build_payment_fixture
  end

  test "manager navigates payments list and detail view" do
    authenticate_as(@manager)

    visit payments_path

    assert_text "All Payments"
    assert_selector "tbody#payments tr", minimum: 1
    assert_text "##{@payment.id}"

    within "tbody#payments" do
      click_link "View", href: payment_path(@payment)
    end

    assert_text "Payment ##{@payment.id}"
    assert_text @payment.category
  end

  test "sender attempting to open payment form is blocked" do
    authenticate_as(@sender)

    visit new_payment_path

    assert_current_path root_path
    assert_selector "#alert-flash", visible: :all
  end

  private

  def cleanup_records
    Payment.delete_all
    ProofUpload.delete_all
    CarrierPayout.delete_all
    Task.delete_all
    CarrierMembership.delete_all
    Messenger.delete_all
    Carrier.delete_all
    Sender.delete_all
    Customer.delete_all
    User.delete_all
  end

  def build_payment_fixture
    @manager = User.create!(
      email: "manager-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      role: :manager
    )

    @sender = User.create!(
      email: "sender-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      role: :sender
    )

    carrier = Carrier.create!(
      name: "Carrier #{SecureRandom.hex(3)}",
      email: "carrier-#{SecureRandom.hex(3)}@example.com",
      address: "800 Carrier Way",
      carrier_type: "Express"
    )

    sender = Sender.create!(
      name: "Sender #{SecureRandom.hex(3)}",
      email: "sender-#{SecureRandom.hex(4)}@example.com",
      phone: "+15552223333",
      address: "789 Sender Road",
      sender_type: :business,
      company_name: "SenderCo",
      tax_id: "TX-#{SecureRandom.hex(3)}"
    )

    customer = Customer.create!(
      name: "Customer #{SecureRandom.hex(3)}",
      email: "customer-#{SecureRandom.hex(4)}@example.com",
      address: "100 Customer Blvd",
      phones: [ "+15550001111" ],
      category: :business
    )

    task = Task.create!(
      customer: customer,
      carrier: carrier,
      sender: sender,
      task_type: "delivery_and_pickup",
      package_type: "parcel",
      start: "Origin",
      target: "Destination",
      status: :delivered,
      barcode: "TSK#{SecureRandom.hex(5)}",
      delivery_time: Time.current,
      priority: :normal
    )

    @payment = Payment.create!(
      category: :service_fee,
      task: task,
      payable: customer,
      payment_type: :per_task,
      interval_start: Date.today - 1.day,
      interval_end: Date.today + 7.days,
      amount_cents: 15_000,
      gateway_status: :succeeded
    )
  end
end
