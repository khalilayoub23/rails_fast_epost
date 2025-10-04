require "test_helper"
require "tempfile"

class PdfEditorTest < ActionDispatch::IntegrationTest
  setup do
    @schema = { "title" => "A", "fields" => [ { "name"=>"n", "x"=>10, "y"=>10 } ] }
    @data1  = { "n"=>"1" }
    @data2  = { "n"=>"2" }
  end

  test "merge combines pages from multiple files" do
    ENV["PDF_DETERMINISTIC"] = "1"
    pdf1 = Pdf::TemplateRenderer.render(schema: @schema, data: @data1)
    pdf2 = Pdf::TemplateRenderer.render(schema: @schema, data: @data2)

    # Write to temp files to simulate filesystem inputs
    f1 = Tempfile.new([ "a", ".pdf" ]) ; f1.binmode ; f1.write(pdf1) ; f1.flush
    f2 = Tempfile.new([ "b", ".pdf" ]) ; f2.binmode ; f2.write(pdf2) ; f2.flush

    merged = Pdf::Editor.merge(paths: [ f1.path, f2.path ])
    assert_operator merged.bytesize, :>, 200

    # Open merged and ensure at least 2 pages exist
    require "hexapdf"
  doc = HexaPDF::Document.new(io: StringIO.new(merged))
    assert_equal 2, doc.pages.count
  ensure
    f1.close! if f1
    f2.close! if f2
  end

  test "stamp_text overlays text on pages" do
    ENV["PDF_DETERMINISTIC"] = "1"
    pdf = Pdf::TemplateRenderer.render(schema: @schema, data: @data1)

    stamped = Pdf::Editor.stamp_text(pdf_bytes: pdf, text: "WATERMARK", at: [ 100, 100 ], size: 14)
    assert_operator stamped.bytesize, :>, 100
    # Sanity: merged bytes differ from original, indicating edit occurred
    assert_not_equal pdf.byteslice(0, 128), stamped.byteslice(0, 128)
  end
end
