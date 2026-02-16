require "application_system_test_case"
require "securerandom"

class AdminSendersUiTest < ApplicationSystemTestCase
  setup do
    @admin = User.create!(
      email: "admin-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      role: :admin
    )

    @sender = Sender.create!(
      name: "Sender #{SecureRandom.hex(2)}",
      email: "sender-#{SecureRandom.hex(4)}@example.com",
      phone: "+15551112222",
      address: "123 Sender Plaza",
      sender_type: :business,
      company_name: "Sender Corp",
      tax_id: "TX-#{SecureRandom.hex(3)}"
    )

    Sender.create!(
      name: "Backup Sender",
      email: "backup-#{SecureRandom.hex(4)}@example.com",
      phone: "+15553334444",
      address: "456 Alternate Way",
      sender_type: :business,
      company_name: "Backup Co",
      tax_id: "TX-#{SecureRandom.hex(3)}"
    )
  end

  test "admin views sender list with metrics" do
    authenticate_as(@admin)

    visit admin_senders_path

    assert_text "Senders"
    assert_selector "table tbody tr", minimum: 2
    assert_text @sender.display_name
    assert_text "Carrier Score"
  end

  test "admin sees empty state when filters exclude all senders" do
    authenticate_as(@admin)

    visit admin_senders_path(search: SecureRandom.hex(16))

    assert_text "No senders match your filters yet."
    assert_selector "tbody tr", count: 1
  end

  private
end
