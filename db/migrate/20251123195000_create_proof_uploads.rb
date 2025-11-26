class CreateProofUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :proof_uploads do |t|
      t.references :task, null: false, foreign_key: true
      t.references :carrier, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.string :category, null: false, default: "photo"
      t.text :notes
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :proof_uploads, :category
  end
end
