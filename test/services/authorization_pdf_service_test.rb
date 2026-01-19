require "test_helper"

class AuthorizationPdfServiceTest < ActiveSupport::TestCase
  test "generates authorization pdf with qr" do
    delivery = build_delivery!(case_number: "CASE-AUTH-001")

    assert_nil delivery.authorization_generated_at
    fake_renderer = Class.new { def to_pdf = "%PDF-1.4 fake" }.new

    Grover.stub(:new, ->(*_) { fake_renderer }) do
      AuthorizationPdfService.new(delivery).generate_and_attach
    end

    delivery.reload
    assert delivery.authorization_pdf.attached?
    assert delivery.authorization_generated_at.present?
  end
end
