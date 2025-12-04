require "rqrcode"
require "chunky_png"
require "barby"
require "barby/barcode/code_128"
require "barby/outputter/png_outputter"

class BarcodeGenerator
  class << self
    def generate_qr(data, size: 300)
      return "" if data.blank?

      qr = RQRCode::QRCode.new(data.to_s)
      png = qr.as_png(size: size, border_modules: 2, color_mode: ChunkyPNG::COLOR_GRAYSCALE)
      png.to_s
    end

    def generate_code128(data)
      return "" if data.blank?

      barcode = Barby::Code128B.new(data.to_s)
      Barby::PngOutputter.new(barcode).to_png(xdim: 2, height: 60, margin: 4)
    end
  end
end
