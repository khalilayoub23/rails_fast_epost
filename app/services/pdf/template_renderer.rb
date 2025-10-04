module Pdf
  class TemplateRenderer
    # Renders a PDF based on a template schema and a data hash
    # schema: { "title": String, "fields": [ {"name","x","y","font_size"} ] }
    # data: { "field_name" => "value" }
    def self.render(schema:, data: {}, filename: "document.pdf")
      title = schema["title"].presence || "Document"
      fields = Array(schema["fields"]) || []

      io = StringIO.new
      doc = HexaPDF::Document.new
      # Enable deterministic output for testing/snapshots
      if ENV["PDF_DETERMINISTIC"].to_s == "1"
        # Fixed seed for trailer ID
        doc.config["document.id_seed"] = "fixed-seed"
      end
      page = doc.pages.add
      canvas = page.canvas

      # Title
      canvas.font("Helvetica", size: 16)
      canvas.text(title, at: [ 50, 800 ])

      # Fields
      canvas.font("Helvetica", size: 12)
      fields.each do |f|
        name = f["name"].to_s
        next if name.blank?
        value = data[name].to_s
        x = (f["x"] || 50).to_f
        y = (f["y"] || 700).to_f
        size = (f["font_size"] || 12).to_f
        canvas.font("Helvetica", size: size)
        canvas.text("#{name}: #{value}", at: [ x, y ])
      end

      # Set fixed metadata timestamps if deterministic
      if ENV["PDF_DETERMINISTIC"].to_s == "1"
        info = doc.trailer.info
        info.set(:Producer, "FastEpost")
        info.set(:Creator, "FastEpost")
        info.set(:CreationDate, Time.at(0))
        info.set(:ModDate, Time.at(0))
      end

      doc.write(io)
      io.string
    rescue NameError
      # Fallback to Prawn in case hexapdf isn't loaded (shouldn't happen if gem installed)
      pdf = Prawn::Document.new
      pdf.text(title, size: 16)
      fields.each do |f|
        name = f["name"].to_s
        value = data[name].to_s
        pdf.text("#{name}: #{value}")
      end
      pdf.render
    end
  end
end
