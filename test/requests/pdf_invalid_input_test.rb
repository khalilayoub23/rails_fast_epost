require "test_helper"

class PdfInvalidInputTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:manager)
    sign_in @user
    @customer = customers(:one)
  end

  test "invalid form params return 422 on create" do
    # Missing address and invalid form_default_url
    post customer_forms_path(@customer), params: { form: { address: "", form_default_url: "not-a-url", data: {} } }, as: :json
    assert_response :unprocessable_entity
  end

  test "invalid template schema returns 422 on create" do
    post form_templates_path, params: { form_template: { carrier_id: carriers(:one).id, customer_id: @customer.id, schema: "not_json" } }, as: :json
    assert_response :unprocessable_entity
  end
end
