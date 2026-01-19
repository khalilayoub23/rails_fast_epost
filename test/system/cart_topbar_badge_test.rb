require "application_system_test_case"

class CartTopbarBadgeTest < ApplicationSystemTestCase
  test "topbar cart badge increments and clears" do
    sender = users(:sender)

    Cart.for(sender).cart_items.destroy_all

    login_as sender

    visit new_task_path

    fill_in "Package Type", with: "Cart Badge Parcel"
    fill_in "Pickup location", with: "Cart Start"
    fill_in "Drop-off location", with: "Cart Target"
    fill_in "Delivery time", with: 1.day.from_now.strftime("%Y-%m-%d %H:%M")

    select customers(:one).name, from: "Customer"

    click_on "Save Task"
    assert_text "Task saved as a draft"

    assert_selector("header a[href='#{cart_path}']", text: "Cart")
    assert_selector("header a[href='#{cart_path}'] span", text: "1")

    find("header a[href='#{cart_path}']").click
    assert_text "Cart"

    click_on "Remove", match: :first
    assert_text "Your cart is empty"
    assert_no_selector("header a[href='#{cart_path}'] span", text: "1", wait: 5)
  end
end
