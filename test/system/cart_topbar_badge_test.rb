require "application_system_test_case"

class CartTopbarBadgeTest < ApplicationSystemTestCase
  test "topbar cart badge increments and clears" do
    sender = users(:sender)
    task = Task.create!(
      customer: customers(:one),
      carrier: carriers(:one),
      sender: senders(:sender_one),
      created_by: sender,
      task_type: "delivery_and_pickup",
      package_type: "parcel",
      start: "Cart Start",
      target: "Cart Target",
      priority: :normal
    )

    Cart.for(sender).cart_items.destroy_all
    Cart.for(sender).add_task!(task)

    login_as sender

    visit cart_path
    assert_text "Cart"
    assert_selector("header a[href='#{cart_path}'] span", text: "1", wait: 5)
    assert_selector("form.button_to[action*='/cart/items/']")

    submit_form_with_request_submit("form.button_to[action*='/cart/items/']")
    assert_text "Your cart is empty"
    assert_no_selector("form.button_to[action*='/cart/items/']")
  end
end
