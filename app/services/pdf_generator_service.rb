require "base64"
require "hexapdf"
require "set"
require "stringio"
require "tempfile"

class PdfGeneratorService
  DEFAULT_FALLBACK_LINES_LIMIT = 14
  DEFAULT_FALLBACK_FONT_SIZE = 9
  DEFAULT_FALLBACK_TEXT_X = 24
  DEFAULT_FALLBACK_BOTTOM_MARGIN = 36
  DEFAULT_FALLBACK_LINE_HEIGHT = 12

  DEFAULT_SIGNATURE_WIDTH = 140
  DEFAULT_TEXT_FONT_SIZE = 10

  OVERLAY_FONT_CANDIDATES = [
    ENV["PDF_OVERLAY_FONT_PATH"],
    "/usr/share/fonts/truetype/noto/NotoSansHebrew-Regular.ttf",
    "/usr/share/fonts/truetype/noto/NotoSansHebrewUI-Regular.ttf",
    Rails.root.join("app/assets/fonts/NotoSansHebrew-Regular.ttf").to_s,
    Rails.root.join("vendor/fonts/NotoSansHebrew-Regular.ttf").to_s,
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
  ].freeze

  class << self
    # Generate PDF from template content using HexaPDF
    def generate_from_template(document_template, variable_values = {})
      return nil unless document_template.prawn_template?

      content = replace_variables(document_template.content, variable_values)

      doc = HexaPDF::Document.new
      page = doc.pages.add
      overlay_font = select_overlay_font(doc)

      render_content(doc: doc, page: page, content: content, overlay_font: overlay_font)

      io = StringIO.new
      doc.write(io)
      io.string
    end

    # Fill existing PDF form fields using HexaPDF
    def fill_form_pdf(document_template, variable_values = {})
      return nil unless document_template.fillable_form? && document_template.pdf_file.attached?

      normalized_values = normalize_variable_values(variable_values)

      if Pdf::FillFastEpost.applicable_template?(document_template)
        input_pdf = document_template.pdf_file.download
        fill_data = Pdf::FillFastEpost.build_data(normalized_values)
        return Pdf::FillFastEpost.fill_bytes(input_pdf_bytes: input_pdf, data: fill_data)
      end

      variable_config = document_template.variables.to_h

      # Download the PDF template
      temp_input = Tempfile.new([ "template", ".pdf" ])
      temp_output = Tempfile.new([ "filled", ".pdf" ])
      temp_input.binmode
      temp_output.binmode

      begin
        # Download attached PDF to temp file
        document_template.pdf_file.download { |chunk| temp_input.write(chunk.b) }
        temp_input.rewind

        # Open PDF with HexaPDF for AcroForm support
        doc = HexaPDF::Document.open(temp_input.path)
        overlay_font = select_overlay_font(doc)

        filled_field_count = fill_acro_form_fields(doc, normalized_values, variable_config)
        mapped_overlay_count = 0

        mapped_overlay_count = stamp_mapped_overlays(doc, normalized_values, variable_config, overlay_font)

        # Persist AcroForm + overlays onto the original template pages.
        doc.write(temp_output.path)

        # Real-world templates are sometimes non-interactive PDFs (no AcroForm fields).
        # In that case, stamp the provided values as an overlay so the output is still populated.
        if filled_field_count.zero? && mapped_overlay_count.zero? && normalized_values.present?
          fallback_doc = HexaPDF::Document.open(temp_output.path)
          fallback_font = select_overlay_font(fallback_doc)
          stamp_variable_values(fallback_doc, normalized_values, fallback_font)
          fallback_doc.write(temp_output.path)
        end

        temp_output.rewind
        temp_output.read
      ensure
        temp_input.close
        temp_input.unlink
        temp_output.close
        temp_output.unlink
      end
    end

    # Hybrid approach: generate base PDF from content, then add form fields
    def generate_hybrid_pdf(document_template, variable_values = {})
      return nil unless document_template.hybrid?

      # First generate from template content if it exists
      if document_template.content.present?
        rendered_pdf = generate_from_template(document_template, variable_values)
        return rendered_pdf if rendered_pdf
      end

      # Fall back to form filling if PDF is attached
      if document_template.pdf_file.attached?
        fill_form_pdf(document_template, variable_values)
      end
    end

    # Generate a simple legal document template
    def generate_simple_document(title, sections = [], options = {})
      doc = HexaPDF::Document.new
      page = doc.pages.add
      canvas = page.canvas
      overlay_font = select_overlay_font(doc)

      top = page.box.respond_to?(:top) ? page.box.top : page.box.height
      y = top - 50

      apply_overlay_font(canvas, overlay_font, size: 18)
      canvas.text(title.to_s, at: [ 50, y ])
      y -= 28

      apply_overlay_font(canvas, overlay_font, size: 10)
      canvas.text("Date: #{options[:date] || Date.current.strftime('%B %d, %Y')}", at: [ 50, y ])
      y -= 26

      sections.each do |section|
        heading = section[:heading].to_s
        body = section[:body].to_s

        if heading.present?
          apply_overlay_font(canvas, overlay_font, size: 14)
          canvas.text(heading, at: [ 50, y ])
          y -= 20
        end

        if body.present?
          apply_overlay_font(canvas, overlay_font, size: 12)
          body.split("\n").each do |line|
            if y < 60
              page = doc.pages.add
              canvas = page.canvas
              top = page.box.respond_to?(:top) ? page.box.top : page.box.height
              y = top - 50
              apply_overlay_font(canvas, overlay_font, size: 12)
            end
            canvas.text(line, at: [ 50, y ])
            y -= 16
          end
          y -= 12
        end
      end

      if options[:include_signature]
        if y < 90
          page = doc.pages.add
          canvas = page.canvas
          top = page.box.respond_to?(:top) ? page.box.top : page.box.height
          y = top - 50
        end

        apply_overlay_font(canvas, overlay_font, size: 12)
        canvas.text("Signature: _______________________________", at: [ 50, y ])
        y -= 18
        canvas.text("Date: ____________________________________", at: [ 50, y ])
      end

      io = StringIO.new
      doc.write(io)
      io.string
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
    def render_content(doc:, page:, content:, overlay_font: nil)
      canvas = page.canvas
      top = page.box.respond_to?(:top) ? page.box.top : page.box.height
      y = top - 50

      content.to_s.split("\n").each do |line|
        text = line.to_s

        if y < 60
          page = doc.pages.add
          canvas = page.canvas
          top = page.box.respond_to?(:top) ? page.box.top : page.box.height
          y = top - 50
        end

        if text.start_with?("#")
          level = [ text[/^#+/].to_s.length, 6 ].min
          header_text = text.sub(/^#+\s*/, "")
          font_size = [ 22 - (level * 2), 10 ].max
          apply_overlay_font(canvas, overlay_font, size: font_size)
          canvas.text(header_text, at: [ 50, y ])
          y -= font_size + 8
        else
          apply_overlay_font(canvas, overlay_font, size: 12)
          canvas.text(text, at: [ 50, y ])
          y -= 16
        end
      end
    end

    def stamp_variable_values(doc, variable_values, overlay_font = nil)
      page = doc.pages.first || doc.pages.add
      canvas = page.canvas(type: :overlay)

      lines = variable_values.to_h
        .reject { |_, value| value.blank? || signature_like_value?(value) }
        .first(DEFAULT_FALLBACK_LINES_LIMIT)
        .map { |key, value| "#{key.to_s.humanize}: #{text_value_for_overlay(value, overlay_font)}" }

      return if lines.empty?

      top = page.box.respond_to?(:top) ? page.box.top : page.box.height
      y = top - 24

      apply_overlay_font(canvas, overlay_font, size: DEFAULT_FALLBACK_FONT_SIZE)
      canvas.fill_color(0.2)

      lines.each do |line|
        break if y < DEFAULT_FALLBACK_BOTTOM_MARGIN

        canvas.text(line, at: [ DEFAULT_FALLBACK_TEXT_X, y ])
        y -= DEFAULT_FALLBACK_LINE_HEIGHT
      end
    end

    def fill_acro_form_fields(doc, values, config)
      return 0 unless doc.acro_form

      form = doc.acro_form
      count = 0
      consumed_keys = Set.new

      config.each do |key, key_config|
        field_name = key_config.to_h.dig("pdf", "field").presence || key_config.to_h["acro_field"].presence || key
        field = form.field_by_name(field_name.to_s)
        next unless field

        value = text_value_for_field(values[key], key: key, key_config: key_config)
        next if value.blank?

        field.field_value = value
        consumed_keys << key.to_s
        count += 1
      end

      values.each do |key, value|
        next if consumed_keys.include?(key.to_s)

        field = form.field_by_name(key.to_s)
        next unless field

        text_value = text_value_for_field(value, key: key)
        next if text_value.blank?

        field.field_value = text_value
        count += 1
      end

      count
    end

    def stamp_mapped_overlays(doc, values, config, overlay_font)
      count = 0

      config.each do |key, key_config|
        key_config = key_config.to_h
        pdf_config = key_config["pdf"].to_h
        next if pdf_config.blank?
        next unless pdf_config["x"].present? && pdf_config["y"].present?

        page_number = pdf_config["page"].to_i
        page = doc.pages[page_number > 0 ? page_number - 1 : 0] || doc.pages.first || doc.pages.add
        canvas = page.canvas(type: :overlay)
        x = pdf_config["x"].to_f
        y = pdf_config["y"].to_f

        if signature_field?(key, key_config)
          image_data = signature_image_bytes(values[key])
          next if image_data.blank?

          width = (pdf_config["width"].presence || DEFAULT_SIGNATURE_WIDTH).to_f
          height = pdf_config["height"].presence&.to_f
          image = doc.images.add(StringIO.new(image_data))
          image_options = { at: [ x, y ], width: width }
          image_options[:height] = height if height.present?
          canvas.image(image, **image_options)
          count += 1
          next
        end

        text_value = text_value_for_field(values[key], key: key, key_config: key_config)
        next if text_value.blank?

        font_size = (pdf_config["font_size"].presence || DEFAULT_TEXT_FONT_SIZE).to_f
        apply_overlay_font(canvas, overlay_font, size: font_size)
        canvas.fill_color(0.1)
        canvas.text(text_value_for_overlay(text_value, overlay_font), at: [ x, y ])
        count += 1
      end

      count
    end

    def normalize_variable_values(variable_values)
      return {} if variable_values.blank?

      variable_values.to_h.transform_keys(&:to_s)
    end

    def text_value_for_field(value, key: nil, key_config: nil)
      return nil if value.blank?
      return nil if signature_field?(key, key_config)
      return nil if signature_like_value?(value)
      return nil if uploaded_file?(value)

      value.to_s
    end

    def text_value_for_overlay(value, overlay_font_available)
      text = value.to_s
      return text if overlay_font_available

      text.encode("US-ASCII", invalid: :replace, undef: :replace, replace: "?")
    end

    def mapped_overlay_config_present?(config)
      config.any? do |_, key_config|
        pdf_config = key_config.to_h["pdf"].to_h
        pdf_config["x"].present? && pdf_config["y"].present?
      end
    end

    def signature_image_bytes(value)
      return nil if value.blank?

      if uploaded_file?(value)
        if value.respond_to?(:tempfile) && value.tempfile.present?
          return File.binread(value.tempfile.path)
        end

        return value.read if value.respond_to?(:read)
      end

      if value.respond_to?(:download)
        return value.download
      end

      string = value.to_s
      return nil if string.blank?

      if string.start_with?("data:image")
        encoded = string.split(",", 2).last
        return Base64.decode64(encoded)
      end

      if string.match?(/\A[a-zA-Z0-9+\/=\s]+\z/)
        decoded = Base64.decode64(string)
        return decoded if decoded.present?
      end

      nil
    rescue => _e
      nil
    end

    def signature_like_value?(value)
      return true if uploaded_file?(value)

      value.to_s.start_with?("data:image")
    end

    def uploaded_file?(value)
      value.respond_to?(:original_filename) || value.respond_to?(:tempfile)
    end

    def select_overlay_font(doc)
      font_path = select_overlay_font_path
      return nil unless font_path

      doc.fonts.add(font_path)
    rescue => _e
      nil
    end

    def select_overlay_font_path
      OVERLAY_FONT_CANDIDATES.find { |candidate| candidate.present? && File.exist?(candidate) }
    end

    def signature_field?(key, key_config = nil)
      return true if key_config.to_h["type"].to_s == "signature"

      key.to_s.include?("signature")
    end

    def rtl_text?(value)
      value.to_s.match?(/[\p{Hebrew}\p{Arabic}]/)
    rescue
      false
    end

    def apply_overlay_font(canvas, overlay_font, size: 10)
      if overlay_font
        canvas.font(overlay_font, size: size)
      else
        canvas.font("Helvetica", size: size)
      end
    end
  end
end
