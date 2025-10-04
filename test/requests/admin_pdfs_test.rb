require "test_helper"

class AdminPdfsTest < ActionDispatch::IntegrationTest
  setup do
    @schema = { "title" => "A", "fields" => [ { "name"=>"n", "x"=>10, "y"=>10 } ] }
    @data1  = { "n"=>"1" }
    @data2  = { "n"=>"2" }
  end

  test "merge endpoint returns merged pdf" do
    pdf1 = Pdf::TemplateRenderer.render(schema: @schema, data: @data1)
    pdf2 = Pdf::TemplateRenderer.render(schema: @schema, data: @data2)

    file1 = Tempfile.new([ "a", ".pdf" ]) ; file1.binmode ; file1.write(pdf1) ; file1.rewind
    file2 = Tempfile.new([ "b", ".pdf" ]) ; file2.binmode ; file2.write(pdf2) ; file2.rewind

    post merge_admin_pdfs_path, params: { files: [ Rack::Test::UploadedFile.new(file1.path, "application/pdf"), Rack::Test::UploadedFile.new(file2.path, "application/pdf") ] }
    assert_response :success
    assert_equal "application/pdf", @response.media_type
  ensure
    file1.close! if file1
    file2.close! if file2
  end

  test "stamp endpoint returns stamped pdf" do
    pdf = Pdf::TemplateRenderer.render(schema: @schema, data: @data1)
    file = Tempfile.new([ "c", ".pdf" ]) ; file.binmode ; file.write(pdf) ; file.rewind

    post stamp_admin_pdfs_path, params: { file: Rack::Test::UploadedFile.new(file.path, "application/pdf"), text: "WATERMARK", x: 50, y: 50, size: 12 }
    assert_response :success
    assert_equal "application/pdf", @response.media_type
  ensure
    file.close! if file
  end
end
