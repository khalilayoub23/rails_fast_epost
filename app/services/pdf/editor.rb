module Pdf
  class Editor
    # Merge multiple PDF files into a single PDF (order preserved)
    # paths: array of absolute or relative filesystem paths to PDFs
    # returns: binary String of merged PDF
    def self.merge(paths: [])
      raise ArgumentError, "paths must be an Array" unless paths.is_a?(Array)
      require "hexapdf"

      target = HexaPDF::Document.new
      paths.each do |path|
        next if path.to_s.strip.empty?
        src = HexaPDF::Document.open(path)
        src.pages.each do |src_page|
          imported = target.import(src_page)
          # Add imported page at the end
          target.pages.add(imported)
        end
      end

      io = StringIO.new
      if ENV["PDF_DETERMINISTIC"].to_s == "1"
        target.config["document.id_seed"] = "fixed-seed-merge"
        info = target.trailer.info
        info[:Producer] = "FastEpost"
        info[:Creator] = "FastEpost"
        info[:CreationDate] = Time.at(0)
        info[:ModDate] = Time.at(0)
      end
      target.write(io)
      io.string
    end

    # Stamp simple text onto all pages of the provided PDF bytes
    # at: [x, y] coordinates; size: font size
    def self.stamp_text(pdf_bytes:, text:, at: [ 50, 50 ], size: 12)
      require "hexapdf"
  io_in = StringIO.new(pdf_bytes)
  doc = HexaPDF::Document.new(io: io_in)

      doc.pages.each do |page|
        # Use overlay to add content on top of existing page contents
        canvas = page.canvas(type: :overlay)
        canvas.font("Helvetica", size: size)
        canvas.text(text.to_s, at: at)
      end

      io_out = StringIO.new
      if ENV["PDF_DETERMINISTIC"].to_s == "1"
        doc.config["document.id_seed"] = "fixed-seed-stamp"
        info = doc.trailer.info
        info[:Producer] = "FastEpost"
        info[:Creator] = "FastEpost"
        info[:CreationDate] = Time.at(0)
        info[:ModDate] = Time.at(0)
      end
      doc.write(io_out)
      io_out.string
    end

    # Insert a blank page at a given position (0-based index)
    def self.insert_page(pdf_bytes:, index: 0, size: :A4)
      require "hexapdf"
      doc = HexaPDF::Document.new(io: StringIO.new(pdf_bytes))
      page = doc.pages.add_page(size)
      doc.pages.insert(index, page)
      io = StringIO.new
      doc.write(io)
      io.string
    end

    # Rotate all pages by degrees (multiple of 90)
    def self.rotate_pages(pdf_bytes:, degrees: 90)
      require "hexapdf"
      doc = HexaPDF::Document.new(io: StringIO.new(pdf_bytes))
      doc.pages.each do |page|
        page.rotate(degrees)
      end
      io = StringIO.new
      doc.write(io)
      io.string
    end

    # Crop all pages to the specified rectangle [llx, lly, urx, ury]
    def self.crop_pages(pdf_bytes:, box: [ 0, 0, 400, 600 ])
      require "hexapdf"
      doc = HexaPDF::Document.new(io: StringIO.new(pdf_bytes))
      doc.pages.each do |page|
        page.box(:CropBox, box)
      end
      io = StringIO.new
      doc.write(io)
      io.string
    end
  end
end
