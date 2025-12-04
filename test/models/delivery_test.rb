require "test_helper"

class DeliveryTest < ActiveSupport::TestCase
  setup do
    @sender = users(:lawyer_user)
    @recipient = users(:recipient_user)
    @courier = users(:courier_user)
    purge_signatures
    @original_signature_requirement = Rails.configuration.x.deliveries.require_saved_signatures
    Rails.configuration.x.deliveries.require_saved_signatures = false
  end

  teardown do
    Rails.configuration.x.deliveries.require_saved_signatures = @original_signature_requirement
  end

  test "auto assigns uppercase case number when omitted" do
    delivery = Delivery.create!(sender: @sender, recipient: @recipient, courier: @courier)

    assert_match(/\ACASE-#{Time.current.year}-[A-Z0-9]{6}\z/, delivery.case_number)
  end

  test "keeps provided case number after normalization" do
    delivery = Delivery.create!(
      sender: @sender,
      recipient: @recipient,
      courier: @courier,
      case_number: " abc123 "
    )

    assert_equal "ABC123", delivery.case_number
  end

  test "requires lawyer and courier signatures when flag enabled" do
    with_signature_requirement(true) do
      delivery = Delivery.new(sender: @sender, recipient: @recipient, courier: @courier)

      assert_not delivery.valid?
      assert_includes delivery.errors[:courier], "must have a saved signature before delivery can be created"
      assert_includes delivery.errors[:sender], "lawyers must have a saved signature on file"
    end
  end

  test "allows delivery creation without signatures when flag disabled" do
    with_signature_requirement(false) do
      assert_difference("Delivery.count", 1) do
        Delivery.create!(sender: @sender, recipient: @recipient, courier: @courier)
      end
    end
  end

  private

  def purge_signatures
    [ @sender, @courier ].each do |user|
      user.saved_signature.purge if user.saved_signature.attached?
    end
  end

  def with_signature_requirement(value)
    original = Rails.configuration.x.deliveries.require_saved_signatures
    Rails.configuration.x.deliveries.require_saved_signatures = value
    yield
  ensure
    Rails.configuration.x.deliveries.require_saved_signatures = original
  end
end
