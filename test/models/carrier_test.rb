require "test_helper"

class CarrierTest < ActiveSupport::TestCase
  test "should create carrier with valid attributes" do
    carrier = Carrier.new(
      name: "Test Carrier",
      email: "test@carrier.com",
      carrier_type: "express",
      address: "123 Test St"
    )
    assert carrier.valid?
  end

  test "should have many tasks" do
    carrier = carriers(:one)
    assert_respond_to carrier, :tasks
  end

  test "should have many documents" do
    carrier = carriers(:one)
    assert_respond_to carrier, :documents
  end

  test "should have many phones" do
    carrier = carriers(:one)
    assert_respond_to carrier, :phones
  end

  test "should have one preference" do
    carrier = carriers(:one)
    assert_respond_to carrier, :preference
  end
end
