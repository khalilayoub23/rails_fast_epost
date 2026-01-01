require "application_system_test_case"

class TaskPublicationFlowTest < ApplicationSystemTestCase
  test "sender saves draft then pays to publish" do
    sender = users(:sender)
    login_as sender

    visit new_task_path

    fill_in "Package Type", with: "Draft Parcel"
    fill_in "Pickup location", with: "Draft Start"
    fill_in "Drop-off location", with: "Draft Target"
    fill_in "Delivery time", with: 1.day.from_now.strftime("%Y-%m-%d %H:%M")

    select customers(:one).name, from: "Customer"

    click_on "Save Task"

    assert_text "Task saved as a draft"
    assert_text "Draft Parcel"

    fill_in "payment_amount", with: "150"
    select "USD", from: "payment_currency"
    select "Standard Delivery", from: "payment_service_type"
    fill_in "payment_description", with: "Publish draft"

    # We only assert the button exists; Stripe checkout would be external.
    assert_button "Pay & Publish Task"
  end
end
