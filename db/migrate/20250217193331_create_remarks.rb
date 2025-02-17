class CreateRemarks < ActiveRecord::Migration[8.0]
  def change
    create_table :remarks do |t|
      t.references :task_id, null: false, foreign_key: true
      t.integer :remarkable_id
      t.string :remarkable_type
      t.text :content

      t.timestamps
    end
  end
end
