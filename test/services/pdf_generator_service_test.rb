require "test_helper"
require "base64"
require "stringio"
require "tempfile"
require "hexapdf"

class PdfGeneratorServiceTest < ActiveSupport::TestCase
  def setup
    @template = DocumentTemplate.create!(
      name: "Test Template",
      template_type: :prawn_template,
      content: "# Invoice\n\nBill to: {{customer_name}}\nAmount: {{amount}}",
      category: "Commercial Invoice",
      active: true
    )
    @template.update_variables_schema!

    @variable_values = {
      "customer_name" => "John Doe",
      "amount" => "$100.00"
    }
  end

  # Generate from Template Tests
  test "generate_from_template should create PDF" do
    pdf_string = PdfGeneratorService.generate_from_template(@template, @variable_values)

    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
    assert pdf_string.length > 100
  end

  test "generate_from_template should handle templates with variables" do
    pdf_string = PdfGeneratorService.generate_from_template(@template, @variable_values)

    # Verify PDF is generated successfully
    assert_not_nil pdf_string
    assert pdf_string.length > 0
    assert pdf_string.start_with?("%PDF")
  end

  test "generate_from_template should handle templates without variables" do
    simple_template = DocumentTemplate.create!(
      name: "Simple",
      template_type: :prawn_template,
      content: "# Simple Document\n\nNo variables here.",
      active: true
    )

    pdf_string = PdfGeneratorService.generate_from_template(simple_template, {})
    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
  end

  test "generate_from_template should handle markdown headers" do
    markdown_template = DocumentTemplate.create!(
      name: "Markdown",
      template_type: :prawn_template,
      content: "# Title\n## Subtitle\n### Section\n\nParagraph text.",
      active: true
    )

    pdf_string = PdfGeneratorService.generate_from_template(markdown_template, {})
    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
  end

  test "generate_from_template should handle empty content" do
    empty_template = DocumentTemplate.create!(
      name: "Empty",
      template_type: :prawn_template,
      content: "",
      active: true
    )

    pdf_string = PdfGeneratorService.generate_from_template(empty_template, {})
    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
  end

  test "generate_from_template should handle nil variable values" do
    pdf_string = PdfGeneratorService.generate_from_template(@template, nil)
    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
  end

  # Generate Simple Document Tests
  test "generate_simple_document should create PDF with title" do
    pdf_string = PdfGeneratorService.generate_simple_document(
      "Test Document",
      [ { heading: "Section 1", body: "Content here" } ]
    )

    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
  end

  test "generate_simple_document should handle multiple sections" do
    sections = [
      { heading: "Introduction", body: "Welcome" },
      { heading: "Details", body: "Important information" },
      { heading: "Conclusion", body: "Thank you" }
    ]

    pdf_string = PdfGeneratorService.generate_simple_document("Multi-Section", sections)
    assert_not_nil pdf_string
    assert pdf_string.length > 0
    assert pdf_string.start_with?("%PDF")
  end

  test "generate_simple_document should accept options" do
    options = { page_size: "LETTER", page_layout: :portrait }
    pdf_string = PdfGeneratorService.generate_simple_document(
      "Custom Options",
      [ { heading: "Test", body: "Body" } ],
      options
    )

    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
  end

  test "generate_simple_document should handle empty sections" do
    pdf_string = PdfGeneratorService.generate_simple_document("Empty", [])
    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
  end

  test "generate_simple_document should handle sections without heading" do
    pdf_string = PdfGeneratorService.generate_simple_document("Title", [ { body: "Just body text" } ])
    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
  end

  test "fill_form_pdf supports mapped overlays and signature image" do
    base_pdf = HexaPDF::Document.new
    base_pdf.pages.add
    temp_pdf = Tempfile.new([ "base-template", ".pdf" ])
    base_pdf.write(temp_pdf.path)
    temp_pdf.rewind

    template = DocumentTemplate.create!(
      name: "Overlay Fillable Template",
      template_type: :fillable_form,
      category: "Other",
      active: true,
      variables: {
        "customer_name" => {
          "type" => "string",
          "pdf" => { "page" => 1, "x" => 60, "y" => 740, "font_size" => 11 }
        },
        "sender_signature" => {
          "type" => "signature",
          "pdf" => { "page" => 1, "x" => 60, "y" => 700, "width" => 120, "height" => 36 }
        }
      }
    )

    template.pdf_file.attach(
      io: File.open(temp_pdf.path, "rb"),
      filename: "overlay-base.pdf",
      content_type: "application/pdf"
    )

    tiny_png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AApMBgN7fD2wAAAAASUVORK5CYII=")
    signature_data_url = "data:image/png;base64,#{Base64.strict_encode64(tiny_png)}"

    pdf_string = PdfGeneratorService.fill_form_pdf(
      template,
      {
        "customer_name" => "שלום לקוח",
        "sender_signature" => signature_data_url
      }
    )

    assert_not_nil pdf_string
    assert pdf_string.start_with?("%PDF")
    assert pdf_string.length > 500
  ensure
    temp_pdf&.close
    temp_pdf&.unlink
  end
end
