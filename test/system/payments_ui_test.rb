require "application_system_test_case"

class PaymentsUiTest < ApplicationSystemTestCase
  setup do
    @manager = users(:manager)
    @viewer = users(:viewer)
    @payment = payments(:one)
  end

  test "manager navigates payments list and detail view" do
    sign_in_through_ui(@manager)

    visit payments_path

    assert_text "All Payments"
    assert_selector "tbody#payments tr", minimum: 1
    assert_text "##{@payment.id}"

    within "tbody#payments" do
      click_link "View", href: payment_path(@payment)
    end

    assert_text "Payment ##{@payment.id}"
    assert_text @payment.category
  end

  test "viewer attempting to open payment form is blocked" do
    sign_in_through_ui(@viewer)

    visit new_payment_path

    assert_current_path root_path
    assert_selector "#alert-flash"
  end

  private

  def sign_in_through_ui(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign In"

    assert_text "Dashboard"
  end
end
