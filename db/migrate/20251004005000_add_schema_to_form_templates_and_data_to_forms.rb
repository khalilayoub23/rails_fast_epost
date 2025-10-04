class AddSchemaToFormTemplatesAndDataToForms < ActiveRecord::Migration[8.0]
  def change
    add_column :form_templates, :schema, :jsonb, null: false, default: {}
    add_column :forms, :data, :jsonb, null: false, default: {}
  end
end
