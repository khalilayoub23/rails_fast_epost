require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "should create customer with valid attributes" do
    customer = Customer.new(
      name: "Test Customer",
      email: "test@customer.com",
      category: 0,
      address: "123 Test St",
      phones: [ "+1-555-0100" ]
    )
    assert customer.valid?
  end

  test "should have many tasks" do
    customer = customers(:one)
    assert_respond_to customer, :tasks
  end

  test "should have many forms" do
    customer = customers(:one)
    assert_respond_to customer, :forms
  end

  test "should serialize phones as array" do
    customer = Customer.create!(
      name: "Test",
      email: "test@test.com",
      address: "123 Test St",
      category: 0,
      phones: [ "+1-555-0100", "+1-555-0101" ]
    )
    assert_kind_of Array, customer.phones
    assert_equal 2, customer.phones.length
  end
end
