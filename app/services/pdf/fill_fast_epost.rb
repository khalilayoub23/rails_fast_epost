require "hexapdf"
require "stringio"
require "tempfile"

module Pdf
  module FillFastEpost
    TARGET_TEMPLATE_IDS = [ 373615244, 373615243 ].freeze

    FONT_CANDIDATES = [
      ENV["PDF_OVERLAY_FONT_PATH"],
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
      "/usr/share/fonts/truetype/noto/NotoSansHebrew-Regular.ttf",
      "/usr/share/fonts/truetype/noto/NotoSansHebrewUI-Regular.ttf",
      "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
    ].freeze

    PDF_W = 595.276
    PDF_H = 841.890
    IMG_W = 706.0
    IMG_H = 1000.0

    LAWYER_BOX = [ 387, 116, 573, 218 ].freeze
    LAWYER_LINES = [
      { box: [ 395, 120, 568, 133 ], fs: 9, label: nil, labeled: false },
      { box: [ 395, 135, 568, 147 ], fs: 8, label: "נייד", labeled: true },
      { box: [ 395, 149, 568, 161 ], fs: 8, label: "טל", labeled: true },
      { box: [ 395, 163, 568, 174 ], fs: 8, label: nil, labeled: false },
      { box: [ 395, 179, 568, 191 ], fs: 7, label: nil, labeled: false }
    ].freeze

    CASE_NUMBER = [ 93, 119, 174, 127 ].freeze
    JUDGE = [ 93, 143, 179, 155 ].freeze
    LETTER_TYPE = [ 93, 171, 179, 183 ].freeze
    SCHEDULED_DATE = [ 93, 196, 169, 214 ].freeze

    RECIPIENT_NAME = [ 403, 237, 579, 248 ].freeze
    RECIPIENT_ADDRESS = [ 422, 268, 564, 279 ].freeze

    VISIT_ROWS = [
      { postman: [ 478, 306, 553, 317 ], date: [ 335, 306, 401, 317 ], hour: [ 284, 306, 317, 317 ], cb: [ 196, 309, 207, 316 ] },
      { postman: [ 478, 335, 553, 346 ], date: [ 335, 335, 401, 346 ], hour: [ 284, 335, 317, 346 ], cb: [ 196, 337, 207, 344 ] },
      { postman: [ 478, 363, 553, 374 ], date: [ 335, 363, 401, 374 ], hour: [ 284, 363, 317, 374 ], cb: [ 196, 365, 207, 372 ] }
    ].freeze

    DELIVERY_OPTS = {
      "R1" => [ 598, 426, 606, 434 ],
      "R2" => [ 598, 438, 606, 446 ],
      "R3" => [ 598, 451, 606, 460 ],
      "R4" => [ 598, 476, 606, 483 ]
    }.freeze
    FILL_AUTHORIZED = [ 375, 438, 442, 445 ].freeze
    FILL_RECIPIENT_ALT = [ 385, 452, 476, 459 ].freeze

    NO_DELIVERY_OPTS = {
      "L1"  => [ 281, 428, 289, 435 ],
      "L2a" => [ 281, 438, 289, 446 ],
      "L2b" => [ 154, 438, 162, 446 ],
      "L3"  => [ 281, 448, 289, 455 ],
      "L4"  => [ 281, 456, 289, 461 ],
      "L5"  => [ 281, 467, 289, 472 ]
    }.freeze
    FILL_OTHER_REASON = [ 94, 471, 193, 479 ].freeze

    FOOTER_SIGNATURE = [ 94, 518, 195, 527 ].freeze
    FOOTER_POSTMAN = [ 213, 518, 300, 527 ].freeze
    FOOTER_DATE = [ 305, 518, 364, 527 ].freeze
    FOOTER_POSTMAN2 = [ 381, 518, 475, 527 ].freeze
    FOOTER_RECEIVER = [ 549, 518, 614, 527 ].freeze

    class << self
      def applicable_template?(document_template)
        return true if TARGET_TEMPLATE_IDS.include?(document_template.id)

        name = document_template.name.to_s
        downcased = name.downcase

        downcased.include?("legal delivery conformation form") ||
          downcased.include?("legal delivery confirmation form") ||
          name.include?("אישור מסירה")
      end

      def fill(input_pdf_path:, output_pdf_path:, data:)
        output = fill_bytes(input_pdf_bytes: File.binread(input_pdf_path), data: data)
        File.binwrite(output_pdf_path, output)
        output_pdf_path
      end

      def fill_bytes(input_pdf_bytes:, data:)
        temp_input = Tempfile.new([ "fast-epost-template", ".pdf" ])
        temp_input.binmode
        temp_input.write(input_pdf_bytes)
        temp_input.rewind

        doc = HexaPDF::Document.open(temp_input.path)
        page = doc.pages[0]
        canvas = page.canvas(type: :overlay)
        font = doc.fonts.add(select_font_path, custom_encoding: false)

        draw_lawyer_block(canvas, font, data)

        draw_right(canvas, font, CASE_NUMBER, data[:case_number], 9)
        draw_right(canvas, font, JUDGE, data[:judge], 9)
        draw_right(canvas, font, LETTER_TYPE, data[:letter_type], 9)
        draw_right(canvas, font, SCHEDULED_DATE, format_date(data[:scheduled_date]), 9)

        draw_center(canvas, font, RECIPIENT_NAME, data[:recipient_name], 10)
        draw_center(canvas, font, RECIPIENT_ADDRESS, data[:recipient_address], 10)

        Array(data[:visits]).first(3).each_with_index do |visit, index|
          row = VISIT_ROWS[index]
          draw_x(canvas, row[:cb])
          draw_center(canvas, font, row[:postman], visit[:postman], 9)
          draw_center(canvas, font, row[:date], format_date(visit[:date]), 9)
          draw_center(canvas, font, row[:hour], visit[:hour], 8)
        end

        # delivery_option may be a String ("R1") or Array (["R1","R2",...])
        Array(data[:delivery_option]).map(&:to_s).each do |delivery_option|
          next unless DELIVERY_OPTS.key?(delivery_option)

          draw_x(canvas, DELIVERY_OPTS[delivery_option])
          draw_right(canvas, font, FILL_AUTHORIZED, data[:authorized_name], 9) if delivery_option == "R2"
          draw_right(canvas, font, FILL_RECIPIENT_ALT, data[:recipient_alt_name], 9) if delivery_option == "R3"
        end

        # no_delivery_reason may be a String or Array
        Array(data[:no_delivery_reason]).map(&:to_s).each do |no_delivery_reason|
          next unless NO_DELIVERY_OPTS.key?(no_delivery_reason)

          draw_x(canvas, NO_DELIVERY_OPTS[no_delivery_reason])
          draw_right(canvas, font, FILL_OTHER_REASON, data[:other_reason], 9) if no_delivery_reason == "L5"
        end

        postman_name = data[:postman_name].to_s
        delivery_date = data[:delivery_date].to_s
        draw_center(canvas, font, FOOTER_SIGNATURE, data[:signature_name], 9)
        draw_center(canvas, font, FOOTER_POSTMAN, postman_name, 10)
        draw_center(canvas, font, FOOTER_DATE, format_date(delivery_date), 9)
        draw_center(canvas, font, FOOTER_POSTMAN2, data[:postman_name_secondary], 10)
        draw_center(canvas, font, FOOTER_RECEIVER, data[:receiver_name], 10)

        io = StringIO.new
        doc.write(io, optimize: true)
        io.string
      ensure
        temp_input&.close
        temp_input&.unlink
      end

      def build_data(values)
        source = values.to_h.transform_keys(&:to_s)

        {
          lawyer_name: source["lawyer_name"],
          lawyer_mobile: source["lawyer_mobile"].presence || source["lawyer_phone"],
          lawyer_phone: source["lawyer_phone"],
          lawyer_email: source["lawyer_email"],
          lawyer_address: source["lawyer_address"],
          case_number: source["case_file_number"].presence || source["task_barcode"],
          judge: source["judge"],
          letter_type: source["letter_type"].presence || source["task_type"],
          scheduled_date: source["scheduled_date"].presence || source["requested_pickup_date"],
          recipient_name: source["recipient_name"].presence || source["customer_name"],
          recipient_address: source["recipient_address"].presence || source["customer_address"],
          visits: build_visits(source),
          delivery_option: source["delivery_option"].presence || "R1",
          authorized_name: source["authorized_name"],
          recipient_alt_name: source["recipient_alt_name"],
          no_delivery_reason: source["no_delivery_reason"],
          other_reason: source["other_reason"],
          postman_name: source["postman_name"].presence || source["messenger_name"].presence || source["carrier_name"],
          receiver_name: source["receiver_name"].presence || source["recipient_name"].presence || source["customer_name"],
          delivery_date: source["delivery_date"],
          signature_name: source["signature_name"].presence || source["postman_name"].presence || source["messenger_name"].presence || source["carrier_name"],
          postman_name_secondary: source["postman_name_secondary"]
        }
      end

      private

      def build_visits(source)
        visits = []
        (1..3).each do |index|
          date = source["visit_#{index}_date"]
          hour = source["visit_#{index}_hour"]
          postman = source["visit_#{index}_postman"]
          next if date.blank? && hour.blank? && postman.blank?

          visits << { date: date, hour: hour, postman: postman }
        end

        # Fallback: populate visit 1 from delivery info when no explicit visits exist
        if visits.empty?
          fallback_date   = source["delivery_date"].presence || source["requested_pickup_date"]
          fallback_hour   = source["delivery_time"].presence  || source["requested_pickup_time"]
          fallback_postman = source["postman_name"].presence  ||
                             source["messenger_name"].presence ||
                             source["carrier_name"]
          if fallback_date.present? || fallback_postman.present?
            visits << { date: fallback_date, hour: fallback_hour, postman: fallback_postman }
          end
        end

        visits
      end

      def draw_lawyer_block(canvas, font, data)
        # The form already has printed Hebrew labels; fill values centered in the box.
        values = [
          data[:lawyer_name],
          data[:lawyer_mobile],
          data[:lawyer_phone],
          data[:lawyer_email],
          data[:lawyer_address]
        ]

        LAWYER_LINES.zip(values).each do |line_def, value|
          next if value.blank?

          draw_center(canvas, font, line_def[:box], value.to_s, line_def[:fs])
        end
      end

      def draw_right(canvas, font, box, text, font_size)
        return if text.blank?

        x0, y0, x1, y1 = box_to_pdf(box)
        max_width = [ x1 - x0 - 2, 1 ].max
        display, fitted_size = fit_text_to_box(font, rtl(text.to_s), max_width, font_size)
        width = string_width(canvas, font, display, fitted_size)
        x = [ x0, x1 - width - 1 ].max
        canvas.fill_color(0.1)
        canvas.font(font, size: fitted_size)
        canvas.text(display, at: [ x, baseline_y(y0, y1, fitted_size) ])
      end

      def draw_center(canvas, font, box, text, font_size)
        return if text.blank?

        x0, y0, x1, y1 = box_to_pdf(box)
        max_width = [ x1 - x0 - 2, 1 ].max
        display, fitted_size = fit_text_to_box(font, rtl(text.to_s), max_width, font_size)
        width = string_width(canvas, font, display, fitted_size)
        x = x0 + (x1 - x0 - width) / 2.0
        canvas.fill_color(0.1)
        canvas.font(font, size: fitted_size)
        canvas.text(display, at: [ x, baseline_y(y0, y1, fitted_size) ])
      end

      def draw_labeled(canvas, font, box, label_he, value, font_size)
        return if value.blank?

        x0, y0, x1, = box_to_pdf(box)
        rev_label = rtl("#{label_he}:")
        label_width = string_width(canvas, font, rev_label, font_size)
        space_width = string_width(canvas, font, " ", font_size)
        max_width = [ x1 - x0 - 2, 1 ].max
        available_width = [ max_width - label_width - space_width, 1 ].max
        value_text, fitted_size = fit_text_to_box(font, rtl(value.to_s), available_width, font_size)
        value_width = string_width(canvas, font, value_text, fitted_size)
        start_x = [ x0, x1 - label_width - space_width - value_width - 1 ].max

        canvas.fill_color(0.1)
        canvas.font(font, size: fitted_size)
        y1 = box_to_pdf(box)[3]
        baseline = baseline_y(y0, y1, fitted_size)
        canvas.text(value_text, at: [ start_x, baseline ])
        canvas.text(rev_label, at: [ start_x + value_width + space_width, baseline ])
      end

      def draw_x(canvas, box)
        x0, y0, x1, y1 = box_to_pdf(box)
        center_x = (x0 + x1) / 2.0
        center_y = (y0 + y1) / 2.0
        half = [ [ x1 - x0, y1 - y0 ].min / 2.0 - 0.15, 0.7 ].max
        canvas.stroke_color(0, 0, 0)
        canvas.line_width(1.15)
        canvas.line(center_x - half, center_y - half, center_x + half, center_y + half).stroke
        canvas.line(center_x - half, center_y + half, center_x + half, center_y - half).stroke
      end

      def fit_text_to_box(font, text, max_width, base_size)
        value = text.to_s
        size = [ base_size.to_f, 8.0 ].max
        return [ value, size ] if string_width(nil, font, value, size) <= max_width

        clipped = value.dup
        while clipped.length > 1 && string_width(nil, font, "#{clipped}…", size) > max_width
          clipped = clipped[0...-1]
        end

        [ "#{clipped}…", size ]
      end

      def baseline_y(y0, y1, font_size)
        # Place baseline 2pt above the underline (y0) so text body sits
        # clearly just above the printed line, as in natural form filling.
        y0 + 2
      end

      def format_date(value)
        return value.to_s if value.blank?

        # Convert YYYY-MM-DD → DD/MM/YYYY; leave anything else as-is
        if value.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          parts = value.to_s.split("-")
          "#{parts[2]}/#{parts[1]}/#{parts[0]}"
        else
          value.to_s
        end
      end

      def string_width(canvas, font, text, font_size)
        font.scaling_factor * font.wrapped_font.width_of(text.to_s) * font_size / 1000.0
      rescue StandardError
        text.to_s.length * font_size * 0.52
      end

      def px(value)
        value * PDF_W / IMG_W
      end

      def py(value)
        PDF_H - value * PDF_H / IMG_H
      end

      def box_to_pdf(box)
        x0 = px(box[0])
        x1 = px(box[2])
        y0 = py(box[3])
        y1 = py(box[1])
        [ x0, y0, x1, y1 ]
      end

      def rtl(text)
        value = text.to_s
        return value unless value.match?(/[\u05D0-\u05EA]/)

        value.split(" ").reverse.map do |word|
          word.match?(/[\u05D0-\u05EA]/) ? word.reverse : word
        end.join(" ")
      end

      def select_font_path
        FONT_CANDIDATES.find { |candidate| candidate.present? && File.exist?(candidate) } || "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
      end
    end
  end
end
