require "test_helper"

class TasksCycleFlowTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @carrier = carriers(:one)
    @user = users(:admin)
    sign_in @user
  end

  test "create tasks, add to cart, pay some, badge updates" do
    tasks = []

    3.times do |i|
      assert_difference -> { Task.count }, 1 do
        post tasks_path, params: {
          task: {
            customer_id: @customer.id,
            carrier_id: @carrier.id,
            package_type: "documents",
            start: "Origin #{i}",
            target: "Destination #{i}",
            delivery_time: 1.day.from_now.iso8601,
            status: :pending,
            task_type: "delivery_and_pickup"
          }
        }
      end

      task = Task.order(:created_at).last
      tasks << task

      post add_item_cart_path, params: { task_id: task.id }
      assert_response :see_other
    end

    # ensure cart has 3 items listed
    get cart_path
    assert_response :success
    assert_select 'table tbody tr', 3

    # Simulate a successful payment for the first two tasks
    payment = Payment.create!(
      provider: "stripe",
      payable: @user,
      category: :service_fee,
      payment_type: :lump_sum,
      amount_cents: 2000,
      currency: "ILS",
      metadata: { "task_ids" => [tasks[0].id, tasks[1].id] },
      gateway_status: :succeeded,
      checkout_session_id: "cs_paid"
    )
    payment.tasks << [tasks[0], tasks[1]]

    # Call the cart success endpoint to materialize the paid tasks
    get "/cart/success", params: { session_id: "cs_paid" }
    follow_redirect!
    assert_response :success

    # After payment the cart should have 1 remaining item
    get cart_path
    assert_response :success
    assert_select 'table tbody tr', 1

    # Paid tasks should be published, the leftover should remain draft
    assert tasks[0].reload.published?
    assert tasks[1].reload.published?
    assert_not tasks[2].reload.published?
  end
end
