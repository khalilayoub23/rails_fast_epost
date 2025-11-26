require "test_helper"

class CarrierPayoutSyncTest < ActiveSupport::TestCase
  setup do
    CarrierPayout.delete_all
  end

  test "builds payout from carrier payments" do
    task = tasks(:one)
    carrier = carriers(:one)

    CarrierPayoutSync.call(task: task, carrier: carrier)

    payout = CarrierPayout.find_by(task: task, carrier: carrier)
    assert_not_nil payout
    assert_equal 7500, payout.amount_cents
    assert_equal "scheduled", payout.status
    assert_equal payments(:carrier_pending).interval_end, payout.due_at.to_date
  end

  test "marks payout paid when any payment succeeds" do
    task = tasks(:task_one)
    carrier = carriers(:one)

    CarrierPayoutSync.call(task: task, carrier: carrier)

    payout = CarrierPayout.find_by(task: task, carrier: carrier)
    assert_equal "paid", payout.status
    assert_equal 8200, payout.amount_cents
    assert_not_nil payout.paid_at
  end

  test "removes payout if scoped payments disappear" do
    task = tasks(:one)
    carrier = carriers(:one)
    CarrierPayout.create!(carrier: carrier, task: task, amount_cents: 100, currency: "USD")

    Payment.where(id: payments(:carrier_pending).id).delete_all

    CarrierPayoutSync.call(task: task, carrier: carrier)

    assert_nil CarrierPayout.find_by(task: task, carrier: carrier)
  end
end
