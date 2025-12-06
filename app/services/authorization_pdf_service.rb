class AuthorizationPdfService
  def initialize(delivery)
    @delivery = delivery
  end

  def generate_and_attach
    html = render_html
    pdf = Grover.new(html, format: "A4", margin: { top: "1.5cm", bottom: "1.5cm", left: "1.5cm", right: "1.5cm" }, print_background: true).to_pdf
    io = StringIO.new(pdf)
    filename = "authorization-#{delivery.case_number}.pdf"

    delivery.authorization_pdf.attach(io: io, filename: filename, content_type: "application/pdf")
    delivery.update!(authorization_generated_at: Time.current)
  end

  private

  attr_reader :delivery

  def render_html
    qr_png = BarcodeGenerator.generate_qr(verification_payload)
    qr_data_uri = "data:image/png;base64,#{Base64.strict_encode64(qr_png)}"

    ApplicationController.render(
      template: "legal_documents/authorization",
      layout: false,
      locals: {
        delivery: delivery,
        lawyer: delivery.sender,
        carrier: delivery.courier,
        recipient: delivery.recipient,
        qr_code_data_uri: qr_data_uri
      }
    )
  end

  def verification_payload
    {
      case_number: delivery.case_number,
      delivery_id: delivery.id,
      carrier_id: delivery.courier_id,
      issued_at: Time.current.iso8601
    }.to_json
  end
end