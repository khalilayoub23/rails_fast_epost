require "application_system_test_case"

class TaskPublicationFlowTest < ApplicationSystemTestCase
  test "sender saves draft then pays to publish" do
    sender = users(:sender)
    login_as sender

    visit new_task_path

    find("select[name='task[task_type]']").find("option[value='delivery_and_pickup']").select_option
    fill_in "Pickup location", with: "Draft Start"
    fill_in "Drop-off location", with: "Draft Target"

    select customers(:one).name, from: "Customer"

    click_on "Save Task"

    assert_current_path tasks_path

    visit cart_path
    assert_text I18n.t("cart.title", default: "Cart")
    assert_button I18n.t("cart.pay_selected", default: "Pay selected")
  end
end
