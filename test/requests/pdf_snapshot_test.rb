require "test_helper"
require "digest"

class PdfSnapshotTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @schema = { "title" => "Snapshot", "fields" => [ {"name"=>"a","x"=>10,"y"=>10}, {"name"=>"b","x"=>20,"y"=>20} ] }
    @data   = { "a"=>"1", "b"=>"2" }
  end

  test "renderer produces stable pdf for deterministic input" do
    # Exercise renderer directly to avoid timestamps or nondeterministic IO in HTTP stack
    pdf1 = Pdf::TemplateRenderer.render(schema: @schema, data: @data)
    pdf2 = Pdf::TemplateRenderer.render(schema: @schema, data: @data)

    # Ensure non-zero size
    assert_operator pdf1.bytesize, :>, 100
    assert_operator pdf2.bytesize, :>, 100

    # Digest must be stable across runs when inputs identical
    digest1 = Digest::SHA256.hexdigest(pdf1)
    digest2 = Digest::SHA256.hexdigest(pdf2)
    assert_equal digest1, digest2
  end
end
