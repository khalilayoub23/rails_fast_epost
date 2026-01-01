require "base64"
require "stringio"
require "hexapdf"

class PdfProcessorService
  BARCODE_POSITION = [450, 750].freeze
  BARCODE_WIDTH = 100

  def initialize(delivery)
    @delivery = delivery
  end

  def add_system_barcode_to_court_pdf
    return unless delivery.original_court_pdf.attached?

    Tempfile.create(["delivery-original", ".pdf"]) do |input|
      delivery.original_court_pdf.download { |chunk| input.write(chunk) }
      input.rewind

      document = HexaPDF::Document.open(input.path)
      inject_barcode(document)
      embed_attempt_metadata(document)

      Tempfile.create(["delivery-base", ".pdf"]) do |output|
        document.write(output.path, optimize: true)
        output.rewind
        attach_as_base_and_current(output, source: "original")
      end
    end

    create_pdf_generated_event("original")
  end

  def generate_delivery_form_with_barcode
    qr_png = BarcodeGenerator.generate_qr(delivery.barcode_data)
    qr_data_uri = "data:image/png;base64,#{Base64.strict_encode64(qr_png)}"

    html = ApplicationController.render(
      CourtForms::DeliveryFormComponent.new(delivery: delivery, qr_code_data_uri: qr_data_uri),
      layout: false
    )

    pdf_binary = Grover.new(html, format: "A4", margin: { top: "2cm", bottom: "2cm", left: "2cm", right: "2cm" }, print_background: true).to_pdf

    attach_as_base_and_current(StringIO.new(pdf_binary), source: "generated")
    create_pdf_generated_event("generated")
  end

  def embed_attempt_metadata(document)
    page = document.pages.first || document.pages.add
    canvas = page.canvas

    attempts = delivery.tracking_events.where(event_type: "failed").order(:occurred_at).limit(5)
    return if attempts.empty?

    canvas.font_size(8)
    canvas.fill_color("#555555")

    attempts.each_with_index do |attempt, idx|
      y = page.box.top - 100 - (idx * 12)
      meta = attempt.metadata || {}
      location = meta["location"] || {}
      text = [
        "Attempt ##{meta["attempt_number"] || idx + 1}",
        attempt.occurred_at&.iso8601,
        (location.present? ? "(#{location["lat"]}, #{location["lng"]})" : nil)
      ].compact.join(" ")
      canvas.text(text, at: [50, y])
    end
  end

  private

  attr_reader :delivery

  def inject_barcode(document)
    barcode_png = BarcodeGenerator.generate_qr(delivery.barcode_data)
    image_io = StringIO.new(barcode_png)
    page = document.pages.first || document.pages.add
    page.canvas.image(document.images.add(image_io), at: BARCODE_POSITION, width: BARCODE_WIDTH)
  end

  def attach_as_base_and_current(io, source: "generated")
    timestamp = Time.current.to_i
    filename = "delivery-#{delivery.id || "new"}-base-#{timestamp}.pdf"

    attach_pdf(io, delivery.base_pdf, filename)
    io.rewind
    attach_pdf(io, delivery.current_pdf, filename.gsub("base", "current"))

    delivery.audit_logs.create!(action: "pdf_#{source}_processed", user: delivery.sender, metadata: { source: source })
  end

  def attach_pdf(io, attachment, filename)
    io.rewind if io.respond_to?(:rewind)
    attachment.attach(io: StringIO.new(io.read), filename: filename, content_type: "application/pdf")
  ensure
    io.rewind if io.respond_to?(:rewind)
  end

  def create_pdf_generated_event(source)
    SignatureEvent.create!(
      delivery: delivery,
      user: delivery.sender,
      role: "system",
      action: :pdf_generated,
      metadata: { source: source }
    )
  end
end
