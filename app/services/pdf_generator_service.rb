class PdfGeneratorService
  class << self
    # Generate PDF from Prawn template (blank PDF with content)
    def generate_from_template(document_template, variable_values = {})
      return nil unless document_template.prawn_template?

      content = replace_variables(document_template.content, variable_values)

      Prawn::Document.new do |pdf|
        # Set up document properties
        pdf.font "Helvetica"
        pdf.font_size 12

        # Parse and render content
        render_content(pdf, content, document_template, variable_values)
      end.render
    end

    # Fill existing PDF form fields using HexaPDF
    def fill_form_pdf(document_template, variable_values = {})
      return nil unless document_template.fillable_form? && document_template.pdf_file.attached?

      # Download the PDF template
      temp_input = Tempfile.new([ "template", ".pdf" ])
      temp_output = Tempfile.new([ "filled", ".pdf" ])

      begin
        # Download attached PDF to temp file
        document_template.pdf_file.download { |chunk| temp_input.write(chunk) }
        temp_input.rewind

        # Open PDF with HexaPDF
        doc = HexaPDF::Document.open(temp_input.path)

        # Fill form fields
        if doc.acro_form
          form = doc.acro_form

          variable_values.each do |field_name, value|
            field = form.field_by_name(field_name.to_s)
            field.field_value = value if field
          end

          # Flatten form to make it non-editable (optional)
          # form.flatten
        end

        # Write to output file
        doc.write(temp_output.path)
        temp_output.rewind
        temp_output.read
      ensure
        temp_input.close
        temp_input.unlink
        temp_output.close
        temp_output.unlink
      end
    end

    # Hybrid approach: generate base PDF with Prawn, then add form fields
    def generate_hybrid_pdf(document_template, variable_values = {})
      return nil unless document_template.hybrid?

      # First generate with Prawn if content exists
      if document_template.content.present?
        prawn_pdf = generate_from_template(document_template, variable_values)
        return prawn_pdf if prawn_pdf
      end

      # Fall back to form filling if PDF is attached
      if document_template.pdf_file.attached?
        fill_form_pdf(document_template, variable_values)
      end
    end

    # Generate a simple legal document template
    def generate_simple_document(title, sections = [], options = {})
      Prawn::Document.new(page_size: options[:page_size] || "A4", margin: 50) do |pdf|
        # Header
        pdf.font "Helvetica"
        pdf.font_size 18
        pdf.text title, align: :center, style: :bold
        pdf.move_down 20

        # Date
        pdf.font_size 10
        pdf.text "Date: #{options[:date] || Date.current.strftime('%B %d, %Y')}", align: :right
        pdf.move_down 20

        # Sections
        pdf.font_size 12
        sections.each do |section|
          if section[:heading]
            pdf.font_size 14
            pdf.text section[:heading], style: :bold
            pdf.move_down 10
            pdf.font_size 12
          end

          if section[:body]
            pdf.text section[:body], align: :justify
            pdf.move_down 15
          end
        end

        # Signature section
        if options[:include_signature]
          pdf.move_down 30
          pdf.stroke_horizontal_rule
          pdf.move_down 5
          pdf.text "Signature: _______________________________"
          pdf.move_down 5
          pdf.text "Date: ____________________________________"
        end
      end.render
    end

    private

    # Replace {{variable}} placeholders with actual values
    def replace_variables(content, variable_values)
      return "" if content.blank?
      return content if variable_values.nil? || variable_values.empty?

      result = content.dup
      variable_values.each do |key, value|
        result.gsub!(/\{\{#{key}\}\}/, value.to_s)
      end
      result
    end

    # Render content in PDF
    def render_content(pdf, content, template, variables)
      # Basic rendering - split by paragraphs
      paragraphs = content.split("\n\n")

      paragraphs.each do |paragraph|
        next if paragraph.strip.empty?

        # Check for headers (lines starting with #)
        if paragraph.start_with?("#")
          level = paragraph.match(/^#+/)[0].length
          header_text = paragraph.gsub(/^#+\s*/, "")

          pdf.font_size(18 - (level * 2))
          pdf.text header_text, style: :bold
          pdf.move_down 10
          pdf.font_size 12
        else
          pdf.text paragraph, align: :justify
          pdf.move_down 10
        end
      end
    end
  end
end
