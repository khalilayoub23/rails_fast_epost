module Admin
  class PdfsController < ApplicationController
    protect_from_forgery with: :exception
    before_action :require_admin!

    def new
    end

    def merge
      files = Array(params[:files])
      paths = []
      files.each do |uploaded|
        next unless uploaded.respond_to?(:tempfile)
        paths << uploaded.tempfile.path
      end
      merged = Pdf::Editor.merge(paths: paths)
      send_data merged, filename: "merged.pdf", type: "application/pdf"
    end

    def stamp
      file = params[:file]
      text = params[:text].to_s
      at   = [ params[:x].to_f, params[:y].to_f ]
      size = params[:size].to_i
      size = 12 if size <= 0
      pdf_bytes = file.read
      stamped = Pdf::Editor.stamp_text(pdf_bytes: pdf_bytes, text: text, at: at, size: size)
      send_data stamped, filename: "stamped.pdf", type: "application/pdf"
    end

    def insert
      file = params[:file]
      index = params[:index].to_i
      pdf_bytes = file.read
      result = Pdf::Editor.insert_page(pdf_bytes: pdf_bytes, index: index)
      send_data result, filename: "inserted.pdf", type: "application/pdf"
    end

    def rotate
      file = params[:file]
      degrees = params[:degrees].to_i
      degrees = 90 if degrees % 90 != 0
      pdf_bytes = file.read
      result = Pdf::Editor.rotate_pages(pdf_bytes: pdf_bytes, degrees: degrees)
      send_data result, filename: "rotated.pdf", type: "application/pdf"
    end

    def crop
      file = params[:file]
      llx = params[:llx].to_f
      lly = params[:lly].to_f
      urx = params[:urx].to_f
      ury = params[:ury].to_f
      pdf_bytes = file.read
      result = Pdf::Editor.crop_pages(pdf_bytes: pdf_bytes, box: [ llx, lly, urx, ury ])
      send_data result, filename: "cropped.pdf", type: "application/pdf"
    end
  end
end
