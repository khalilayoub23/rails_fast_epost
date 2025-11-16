require "application_system_test_case"

class ContactFormTest < ApplicationSystemTestCase
  driven_by :rack_test

  test "visitor submits get a quote form and creates inquiry" do
    visit pages_contact_path

    fill_in "Full Name", with: "System Test User"
    fill_in "Email Address", with: "system-test@example.com"
    fill_in "Phone Number", with: "+1 (222) 333-4444"
    select "Legal Document Delivery", from: "Service Type"
    fill_in "Message", with: "Need a rush courier quote for legal filings."

    assert_difference -> { ContactInquiry.count }, 1 do
      click_button "Send Message"
      assert_text "Thank you! We'll get back to you within 24 hours."
    end

    inquiry = ContactInquiry.order(created_at: :desc).first
    assert_equal "System Test User", inquiry.name
    assert_equal "system-test@example.com", inquiry.email
    assert_equal "legal", inquiry.service
    assert_equal "Need a rush courier quote for legal filings.", inquiry.message
  end
end
