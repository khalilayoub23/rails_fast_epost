require "test_helper"

class PhoneTest < ActiveSupport::TestCase
  setup do
    @phone = phones(:one)
  end

  test "belongs to its carrier" do
    assert_equal carriers(:one), @phone.carrier
  end

  test "requires a phone number" do
    @phone.number = nil
    assert_not @phone.valid?
    assert_includes @phone.errors[:number], "can't be blank"
  end
end
