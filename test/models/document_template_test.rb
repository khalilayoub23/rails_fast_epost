require "test_helper"

class DocumentTemplateTest < ActiveSupport::TestCase
  def setup
    @template = DocumentTemplate.new(
      name: "Test Template",
      template_type: :prawn_template,
      content: "# Test\n\nHello {{name}}!",
      category: "Legal Agreement",
      active: true
    )
  end

  # Validation Tests
  test "should be valid with valid attributes" do
    assert @template.valid?
  end

  test "should require name" do
    @template.name = nil
    assert_not @template.valid?
    assert_includes @template.errors[:name], "can't be blank"
  end

  test "should require minimum name length" do
    @template.name = "ab"
    assert_not @template.valid?
    assert_includes @template.errors[:name], "is too short (minimum is 3 characters)"
  end

  test "should limit maximum name length" do
    @template.name = "a" * 201
    assert_not @template.valid?
    assert_includes @template.errors[:name], "is too long (maximum is 200 characters)"
  end

  test "should require template_type" do
    @template.template_type = nil
    assert_not @template.valid?
    assert_includes @template.errors[:template_type], "can't be blank"
  end

  test "should limit category length" do
    @template.category = "a" * 101
    assert_not @template.valid?
    assert_includes @template.errors[:category], "is too long (maximum is 100 characters)"
  end

  # Enum Tests
  test "should have prawn_template type" do
    @template.template_type = :prawn_template
    assert @template.prawn_template?
    assert_equal "prawn_template", @template.template_type
  end

  test "should have fillable_form type" do
    @template.template_type = :fillable_form
    assert @template.fillable_form?
    assert_equal "fillable_form", @template.template_type
  end

  test "should have hybrid type" do
    @template.template_type = :hybrid
    assert @template.hybrid?
    assert_equal "hybrid", @template.template_type
  end

  # Scope Tests
  test "active_templates scope should return only active templates" do
    active_template = DocumentTemplate.create!(name: "Active", template_type: :prawn_template, active: true)
    inactive_template = DocumentTemplate.create!(name: "Inactive", template_type: :prawn_template, active: false)
    
    active_templates = DocumentTemplate.active_templates
    assert_includes active_templates, active_template
    assert_not_includes active_templates, inactive_template
  end

  test "by_category scope should filter by category" do
    legal_template = DocumentTemplate.create!(name: "Legal", template_type: :prawn_template, category: "Legal Agreement")
    customs_template = DocumentTemplate.create!(name: "Customs", template_type: :prawn_template, category: "Customs Declaration")
    
    legal_templates = DocumentTemplate.by_category("Legal Agreement")
    assert_includes legal_templates, legal_template
    assert_not_includes legal_templates, customs_template
  end

  test "by_type scope should filter by template type" do
    prawn_template = DocumentTemplate.create!(name: "Prawn", template_type: :prawn_template)
    fillable_template = DocumentTemplate.create!(name: "Fillable", template_type: :fillable_form)
    
    prawn_templates = DocumentTemplate.by_type(:prawn_template)
    assert_includes prawn_templates, prawn_template
    assert_not_includes prawn_templates, fillable_template
  end

  test "recent scope should order by created_at descending" do
    # Clear any existing templates first
    DocumentTemplate.delete_all
    
    old_template = DocumentTemplate.create!(name: "Old", template_type: :prawn_template, created_at: 2.days.ago)
    new_template = DocumentTemplate.create!(name: "New", template_type: :prawn_template, created_at: 1.day.ago)
    
    recent_templates = DocumentTemplate.recent
    assert_equal new_template, recent_templates.first
  end

  # Variable Extraction Tests
  test "extract_variables_from_content should find variables" do
    @template.content = "Hello {{name}}, your order {{order_id}} is ready!"
    variables = @template.extract_variables_from_content
    
    assert_equal 2, variables.length
    assert_includes variables, "name"
    assert_includes variables, "order_id"
  end

  test "extract_variables_from_content should return empty array for no variables" do
    @template.content = "No variables here"
    assert_empty @template.extract_variables_from_content
  end

  test "extract_variables_from_content should return unique variables" do
    @template.content = "{{name}} and {{name}} again"
    variables = @template.extract_variables_from_content
    assert_equal 1, variables.length
    assert_equal ["name"], variables
  end

  test "extract_variables_from_content should handle nil content" do
    @template.content = nil
    assert_empty @template.extract_variables_from_content
  end

  # Variables Schema Tests
  test "update_variables_schema! should create variables schema" do
    @template.content = "Hello {{customer_name}}!"
    @template.save!
    @template.update_variables_schema!
    
    assert @template.variables.key?("customer_name")
    assert_equal "string", @template.variables["customer_name"]["type"]
    assert_equal "Customer Name", @template.variables["customer_name"]["label"]
    assert @template.variables["customer_name"]["required"]
  end

  test "update_variables_schema! should preserve existing variable configs" do
    @template.content = "{{name}}"
    @template.variables = { "name" => { "type" => "custom", "label" => "Custom Label" } }
    @template.save!
    @template.update_variables_schema!
    
    assert_equal "custom", @template.variables["name"]["type"]
    assert_equal "Custom Label", @template.variables["name"]["label"]
  end

  test "update_variables_schema! should add new variables without removing existing ones" do
    @template.content = "{{name}} {{email}}"
    @template.variables = { "name" => { "type" => "string", "label" => "Name" } }
    @template.save!
    @template.update_variables_schema!
    
    assert @template.variables.key?("name")
    assert @template.variables.key?("email")
    assert_equal 2, @template.variables.keys.length
  end

  # Ready for Use Tests
  test "ready_for_use? should return true for active prawn template with content" do
    @template.save!
    assert @template.ready_for_use?
  end

  test "ready_for_use? should return false for inactive prawn template" do
    @template.active = false
    @template.save!
    assert_not @template.ready_for_use?
  end

  test "ready_for_use? should return false for prawn template without content" do
    @template.content = nil
    @template.save!
    assert_not @template.ready_for_use?
  end

  # Category Constants Tests
  test "CATEGORIES should include common document types" do
    assert_includes DocumentTemplate::CATEGORIES, "Customs Declaration"
    assert_includes DocumentTemplate::CATEGORIES, "Shipping Document"
    assert_includes DocumentTemplate::CATEGORIES, "Commercial Invoice"
    assert_includes DocumentTemplate::CATEGORIES, "Power of Attorney"
    assert_includes DocumentTemplate::CATEGORIES, "Legal Agreement"
  end

  test "CATEGORIES should have 9 entries" do
    assert_equal 9, DocumentTemplate::CATEGORIES.length
  end

  # Defaults Tests
  test "should default active to true" do
    template = DocumentTemplate.new(name: "Test", template_type: :prawn_template)
    assert template.active
  end

  test "should default variables to empty hash" do
    template = DocumentTemplate.new(name: "Test", template_type: :prawn_template)
    template.save!
    assert_equal({}, template.variables)
  end

  test "should default template_type to prawn_template" do
    template = DocumentTemplate.new(name: "Test")
    template.save(validate: false)
    assert_equal "prawn_template", template.template_type
  end
end
