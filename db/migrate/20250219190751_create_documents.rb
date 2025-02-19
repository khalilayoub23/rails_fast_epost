class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.references :carrier, null: false, foreign_key: true
      t.string :id_document
      t.string :signature

      t.timestamps
    end
  end
end
