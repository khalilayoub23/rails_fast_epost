require "test_helper"

class Admin::DocumentTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    sign_in @user
    
    @template = DocumentTemplate.create!(
      name: "Test Template",
      template_type: :prawn_template,
      content: "# Test\n\nHello {{name}}!",
      category: "Legal Agreement",
      active: true
    )
  end

  # Index Tests
  test "should get index" do
    get admin_document_templates_url
    assert_response :success
  end

  test "should list templates" do
    get admin_document_templates_url
    assert_select "h1", "Document Templates"
  end

  test "should filter by category" do
    legal_template = DocumentTemplate.create!(name: "Legal", template_type: :prawn_template, category: "Legal Agreement")
    customs_template = DocumentTemplate.create!(name: "Customs", template_type: :prawn_template, category: "Customs Declaration")
    
    get admin_document_templates_url, params: { category: "Legal Agreement" }
    assert_response :success
  end

  test "should filter by type" do
    get admin_document_templates_url, params: { type: "prawn_template" }
    assert_response :success
  end

  test "should filter by active status" do
    get admin_document_templates_url, params: { active: "true" }
    assert_response :success
  end

  # Show Tests
  test "should show template" do
    get admin_document_template_url(@template)
    assert_response :success
  end

  test "should display template details" do
    get admin_document_template_url(@template)
    assert_select "h1", @template.name
  end

  # New Tests
  test "should get new" do
    get new_admin_document_template_url
    assert_response :success
  end

  test "should display new template form" do
    get new_admin_document_template_url
    assert_select "form"
    assert_select "input[name='document_template[name]']"
  end

  # Create Tests
  test "should create template with valid params" do
    assert_difference("DocumentTemplate.count", 1) do
      post admin_document_templates_url, params: {
        document_template: {
          name: "New Template",
          template_type: :prawn_template,
          content: "Test content {{var}}",
          category: "Shipping Document",
          active: true
        }
      }
    end
    assert_redirected_to admin_document_template_url(DocumentTemplate.last)
    assert_equal "Document template successfully created.", flash[:notice]
  end

  test "should not create template with invalid params" do
    assert_no_difference("DocumentTemplate.count") do
      post admin_document_templates_url, params: {
        document_template: {
          name: "",
          template_type: nil
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should extract variables on create" do
    post admin_document_templates_url, params: {
      document_template: {
        name: "Variable Template",
        template_type: :prawn_template,
        content: "{{name}} and {{email}}",
        active: true
      }
    }
    
    template = DocumentTemplate.last
    assert template.variables.key?("name")
    assert template.variables.key?("email")
  end

  # Edit Tests
  test "should get edit" do
    get edit_admin_document_template_url(@template)
    assert_response :success
  end

  test "should display edit form with data" do
    get edit_admin_document_template_url(@template)
    assert_select "form"
    assert_select "input[name='document_template[name]'][value=?]", @template.name
  end

  # Update Tests
  test "should update template with valid params" do
    patch admin_document_template_url(@template), params: {
      document_template: {
        name: "Updated Name",
        content: "Updated content {{new_var}}"
      }
    }
    assert_redirected_to admin_document_template_url(@template)
    assert_equal "Document template successfully updated.", flash[:notice]
    
    @template.reload
    assert_equal "Updated Name", @template.name
    assert_equal "Updated content {{new_var}}", @template.content
  end

  test "should not update template with invalid params" do
    patch admin_document_template_url(@template), params: {
      document_template: {
        name: ""
      }
    }
    assert_response :unprocessable_entity
  end

  test "should re-extract variables on update" do
    patch admin_document_template_url(@template), params: {
      document_template: {
        content: "{{first_name}} {{last_name}}"
      }
    }
    
    @template.reload
    assert @template.variables.key?("first_name")
    assert @template.variables.key?("last_name")
  end

  # Destroy Tests
  test "should destroy template" do
    assert_difference("DocumentTemplate.count", -1) do
      delete admin_document_template_url(@template)
    end
    assert_redirected_to admin_document_templates_url
    assert_equal "Document template successfully deleted.", flash[:notice]
  end
end
