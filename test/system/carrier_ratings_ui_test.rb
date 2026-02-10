require "application_system_test_case"
require "securerandom"

class CarrierRatingsUiTest < ApplicationSystemTestCase
  setup do
    CarrierMembership.delete_all
    ProofUpload.delete_all
    User.delete_all
    @admin = User.create!(
      email: "admin-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      role: :admin
    )
  end

  test "carrier index and show display rating metrics" do
    seed_rating_data
    authenticate_as(@admin)

    visit carriers_path

    assert_text @carrier.name
    assert_text "Overall Score"
    assert_text formatted_score(@carrier.average_overall_rating)

    carrier_link = find("a", text: @carrier.name, match: :first)
    scroll_to carrier_link, align: :center
    carrier_link.click

    assert_text "Performance"
    assert_text "Sender Score"
    assert_text "Recipient Score"
    assert_text "Task Completion"
    assert_text formatted_score(@carrier.average_sender_rating)
    assert_text formatted_score(@carrier.average_completion_rating)
  end

  test "admin sender page shows carrier performance breakdown" do
    seed_rating_data
    authenticate_as(@admin)

    visit admin_sender_path(@sender)

    assert_text "Carrier Experience"
    assert_text @carrier.name

    within "table" do
      assert_text "Overall"
      assert_text "Sender"
      assert_text "Recipient"
      assert_text "Completion"
      assert_text "Delivered"
      assert_text formatted_score(@carrier.average_overall_rating)
    end

    assert_text formatted_score(@sender.carrier_overall_score)
  end

  test "carriers index lists unrated carriers as N/A" do
    unrated = Carrier.create!(
      name: "Unrated Carrier",
      email: "unrated@example.com",
      address: "10 Empty Lane",
      carrier_type: "Standard"
    )

    authenticate_as(@admin)
    visit carriers_path

    within "tbody" do
      assert_text unrated.name
      assert_text "N/A"
    end
  end

  test "carriers index renders multiple rows for pagination coverage" do
    seed_rating_data
    Carrier.create!(
      name: "Carrier #{SecureRandom.hex(3)}",
      email: "extra-#{SecureRandom.hex(3)}@example.com",
      address: "999 Another Way",
      carrier_type: "Standard"
    )

    authenticate_as(@admin)
    visit carriers_path

    assert_selector "tbody tr", minimum: 2
  end

  test "carriers index shows empty state when there are no carriers" do
    purge_carrier_dependencies
    assert_equal 0, Carrier.count

    authenticate_as(@admin)
    visit carriers_path

    assert_text "No carriers have been added yet."
  end

  private

  def seed_rating_data
    @carrier = Carrier.create!(
      name: "Carrier #{SecureRandom.hex(2)}",
      email: "carrier-#{SecureRandom.hex(2)}@example.com",
      address: "100 Carrier Way",
      carrier_type: "Express"
    )

    customer = Customer.create!(
      name: "Customer #{SecureRandom.hex(2)}",
      email: "customer-#{SecureRandom.hex(2)}@example.com",
      address: "200 Customer Lane",
      phones: [ "+15550000000" ],
      category: :individual
    )

    @sender = Sender.create!(
      name: "Sender #{SecureRandom.hex(2)}",
      email: "sender-#{SecureRandom.hex(2)}@example.com",
      phone: "+15551110000",
      address: "1 Sender Plaza",
      sender_type: :individual
    )

    task = Task.create!(
      customer: customer,
      carrier: @carrier,
      sender: @sender,
      task_type: "delivery_and_pickup",
      package_type: "parcel",
      start: "Origin",
      target: "Destination",
      status: :delivered,
      barcode: "TSK#{SecureRandom.hex(4)}",
      delivery_time: Time.current,
      priority: :normal
    )

    CarrierRating.create!(
      carrier: @carrier,
      task: task,
      completion_score: 5,
      sender_score: 4,
      recipient_score: 3,
      rated_by: "qa@example.com"
    )

    @carrier.reload
  end

  def formatted_score(value)
    format("%.2f", value.to_f)
  end

  def purge_carrier_dependencies
    CarrierRating.delete_all
    CarrierPayout.delete_all
    Task.delete_all
    Document.delete_all
    FormTemplate.delete_all
    Phone.delete_all
    Preference.delete_all
    Messenger.update_all(carrier_id: nil)
    Carrier.delete_all
  end
end
