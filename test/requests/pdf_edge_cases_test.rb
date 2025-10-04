require "test_helper"

class PdfEdgeCasesTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
  end

  test "form pdf 404 when no template and no fallback" do
    form = @customer.forms.create!(address: "a", form_default_url: "http://example.com", data: {})
    # Ensure no template exists for this customer
    FormTemplate.where(customer: @customer).delete_all

    get customer_form_path(@customer, form, format: :pdf)
    assert_response :not_found
    assert_match "No template", @response.body
  end

  test "template pdf preview returns non-empty body" do
    template = FormTemplate.create!(carrier: carriers(:one), customer: @customer, schema: { "title"=>"T", "fields"=>[ { "name"=>"x", "x"=>10, "y"=>10 } ] })
    get form_template_path(template, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", @response.media_type
    assert_operator @response.body.bytesize, :>, 100
  end
end
