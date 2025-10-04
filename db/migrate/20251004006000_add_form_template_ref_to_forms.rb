class AddFormTemplateRefToForms < ActiveRecord::Migration[8.0]
  def change
    add_reference :forms, :form_template, foreign_key: { to_table: :form_templates, on_delete: :nullify }
  end
end
