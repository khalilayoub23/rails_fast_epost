module Pdf
  class TemplateRenderer
    # Renders a PDF based on a template schema and a data hash
    # schema: { "title": String, "fields": [ {"name","x","y","font_size"} ] }
    # data: { "field_name" => "value" }
    def self.render(schema:, data: {}, filename: "document.pdf")
      title = schema["title"].presence || "Document"
      fields = Array(schema["fields"]) || []

      io = StringIO.new
      deterministic = deterministic_output?
      doc = HexaPDF::Document.new
      doc.trailer[:ID] = deterministic_pdf_id.map(&:dup) if deterministic
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
      if deterministic
        info = doc.trailer.info
        info[:Producer] = "FastEpost"
        info[:Creator] = "FastEpost"
        info[:CreationDate] = "D:19700101000000Z"
        info[:ModDate] = "D:19700101000000Z"
      end

      doc.write(io, update_fields: !deterministic)
      io.string
    end

    class << self
      private

      def deterministic_output?
        ENV["PDF_DETERMINISTIC"].to_s == "1"
      end

      def deterministic_pdf_id
        @deterministic_pdf_id ||= [
          "FastEpostPDFID01".b,
          "FastEpostPDFID02".b
        ].freeze
      end
    end
  end
end
