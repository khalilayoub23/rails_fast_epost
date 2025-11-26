require "test_helper"

class CarrierPayoutTest < ActiveSupport::TestCase
  setup do
    @payout = carrier_payouts(:carrier_one_pending)
  end

  test "valid fixture" do
    assert @payout.valid?
  end

  test "outstanding scope excludes paid" do
    outstanding_ids = CarrierPayout.outstanding.pluck(:id)
    assert_includes outstanding_ids, carrier_payouts(:carrier_one_pending).id
    assert_not_includes outstanding_ids, carrier_payouts(:carrier_one_paid).id
  end

  test "cleared scope returns paid" do
    cleared_ids = CarrierPayout.cleared.pluck(:id)
    assert_includes cleared_ids, carrier_payouts(:carrier_one_paid).id
  end
end
