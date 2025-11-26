require "test_helper"

class CarrierMembershipTest < ActiveSupport::TestCase
  test "prevents duplicate assignments" do
    membership = carrier_memberships(:primary_assignment)
    duplicate = CarrierMembership.new(user: membership.user, carrier: membership.carrier)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "user can access carriers through memberships" do
    user = users(:operations_manager)
    assert_includes user.carriers, carriers(:one)
  end
end
