if Rails.env.production? && ENV.fetch("PDF_ENFORCE_HEBREW_FONT", "true") == "true"
  Rails.application.config.after_initialize do
    begin
      rtl_template_exists = false

      DocumentTemplate.active_templates.find_each do |template|
        payload = [
          template.name,
          template.description,
          template.content,
          template.variables.to_json
        ].compact.join(" ")

        if payload.match?(/[\p{Hebrew}\p{Arabic}]/)
          rtl_template_exists = true
          break
        end
      end

      next unless rtl_template_exists

      font_path = PdfGeneratorService.send(:select_overlay_font_path)
      next if font_path.present?

      raise <<~ERROR.squish
        RTL PDF templates are active, but no Hebrew-capable font was found for PDF overlays.
        Provide one using PDF_OVERLAY_FONT_PATH or install NotoSansHebrew-Regular.ttf under
        app/assets/fonts, vendor/fonts, or /usr/share/fonts/truetype/noto.
      ERROR
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
      Rails.logger.warn("[pdf_hebrew_font_guard] skipped: #{e.class}: #{e.message}")
    end
  end
end
