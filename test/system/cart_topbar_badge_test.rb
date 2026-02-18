require "application_system_test_case"

class CartTopbarBadgeTest < ApplicationSystemTestCase
  test "topbar cart badge increments and clears" do
    sender = users(:sender)

    Cart.for(sender).cart_items.destroy_all

    login_as sender

    visit new_task_path

    find("select[name='task[task_type]']").find("option[value='delivery_and_pickup']").select_option
    fill_in "Pickup location", with: "Cart Start"
    fill_in "Drop-off location", with: "Cart Target"

    select customers(:one).name, from: "Customer"

    click_with_retry(:button, "Save Task")

    visit cart_path
    assert_text "Cart"
    assert_selector("form.button_to[action*='/cart/items/']")

    submit_form_with_request_submit("form.button_to[action*='/cart/items/']")
    assert_text "Your cart is empty"
    assert_no_selector("form.button_to[action*='/cart/items/']")
  end
end
