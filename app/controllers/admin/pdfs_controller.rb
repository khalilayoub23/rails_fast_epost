module Admin
  class PdfsController < ApplicationController
    protect_from_forgery with: :exception
    before_action :require_admin!

    def new
    end

    def merge
      files = Array(params[:files]).filter_map { |uploaded| validated_pdf_upload(uploaded) }
      return render_pdf_error("At least one valid PDF file is required.") if files.empty?

      paths = files.map { |uploaded| uploaded.tempfile.path }
      merged = Pdf::Editor.merge(paths: paths)
      send_data merged, filename: "merged.pdf", type: "application/pdf"
    rescue => e
      Rails.logger.error("[Admin::PdfsController#merge] #{e.class}: #{e.message}")
      render_pdf_error("Failed to merge PDFs.")
    end

    def stamp
      file = validated_pdf_upload(params[:file])
      return render_pdf_error("A valid PDF file is required.") unless file

      text = params[:text].to_s
      at   = [ params[:x].to_f, params[:y].to_f ]
      size = params[:size].to_i
      size = 12 if size <= 0
      pdf_bytes = file.read
      stamped = Pdf::Editor.stamp_text(pdf_bytes: pdf_bytes, text: text, at: at, size: size)
      send_data stamped, filename: "stamped.pdf", type: "application/pdf"
    rescue => e
      Rails.logger.error("[Admin::PdfsController#stamp] #{e.class}: #{e.message}")
      render_pdf_error("Failed to stamp PDF.")
    end

    def insert
      file = validated_pdf_upload(params[:file])
      return render_pdf_error("A valid PDF file is required.") unless file

      index = params[:index].to_i
      pdf_bytes = file.read
      result = Pdf::Editor.insert_page(pdf_bytes: pdf_bytes, index: index)
      send_data result, filename: "inserted.pdf", type: "application/pdf"
    rescue => e
      Rails.logger.error("[Admin::PdfsController#insert] #{e.class}: #{e.message}")
      render_pdf_error("Failed to insert PDF page.")
    end

    def rotate
      file = validated_pdf_upload(params[:file])
      return render_pdf_error("A valid PDF file is required.") unless file

      degrees = params[:degrees].to_i
      degrees = 90 if degrees % 90 != 0
      pdf_bytes = file.read
      result = Pdf::Editor.rotate_pages(pdf_bytes: pdf_bytes, degrees: degrees)
      send_data result, filename: "rotated.pdf", type: "application/pdf"
    rescue => e
      Rails.logger.error("[Admin::PdfsController#rotate] #{e.class}: #{e.message}")
      render_pdf_error("Failed to rotate PDF pages.")
    end

    def crop
      file = validated_pdf_upload(params[:file])
      return render_pdf_error("A valid PDF file is required.") unless file

      llx = params[:llx].to_f
      lly = params[:lly].to_f
      urx = params[:urx].to_f
      ury = params[:ury].to_f
      return render_pdf_error("Invalid crop coordinates.") if urx <= llx || ury <= lly

      pdf_bytes = file.read
      result = Pdf::Editor.crop_pages(pdf_bytes: pdf_bytes, box: [ llx, lly, urx, ury ])
      send_data result, filename: "cropped.pdf", type: "application/pdf"
    rescue => e
      Rails.logger.error("[Admin::PdfsController#crop] #{e.class}: #{e.message}")
      render_pdf_error("Failed to crop PDF pages.")
    end

    private

    def validated_pdf_upload(uploaded)
      return nil unless uploaded.respond_to?(:read) && uploaded.respond_to?(:tempfile)
      return nil if uploaded.tempfile.blank?
      return nil if uploaded.respond_to?(:size) && uploaded.size.to_i <= 0

      content_type = uploaded.respond_to?(:content_type) ? uploaded.content_type.to_s : ""
      return nil unless content_type == "application/pdf"

      uploaded
    end

    def render_pdf_error(message)
      render plain: message, status: :unprocessable_entity
    end
  end
end
