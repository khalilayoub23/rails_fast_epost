require "test_helper"

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
end
