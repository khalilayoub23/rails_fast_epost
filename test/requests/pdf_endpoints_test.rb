require "test_helper"

class PdfEndpointsTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @template = FormTemplate.create!(carrier: carriers(:one), customer: @customer, schema: {"title"=>"T","fields"=>[{"name"=>"x","x"=>10,"y"=>10}]})
    @form = @customer.forms.create!(address: "a", form_default_url: "http://example.com", data: {"x"=>"1"}, form_template: @template)
  end

  test "template pdf preview" do
    get form_template_path(@template, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", @response.media_type
  end

  test "form pdf render" do
    get customer_form_path(@customer, @form, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", @response.media_type
  end
end
