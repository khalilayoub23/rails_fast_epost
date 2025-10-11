class CreateDocumentTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :document_templates do |t|
      t.string :name, null: false
      t.text :description
      t.integer :template_type, null: false, default: 0
      t.string :category
      t.jsonb :variables, default: {}
      t.boolean :active, default: true
      t.text :content # For Prawn-based templates (HTML/Markdown/Template string)

      t.timestamps
    end
    
    add_index :document_templates, :name
    add_index :document_templates, :template_type
    add_index :document_templates, :category
    add_index :document_templates, :active
  end
end
