class AddPoaDocumentTemplateToTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :tasks, :poa_document_template, foreign_key: { to_table: :document_templates }
  end
end
