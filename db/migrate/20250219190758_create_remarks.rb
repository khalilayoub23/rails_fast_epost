class CreateRemarks < ActiveRecord::Migration[8.0]
  def change
    create_table :remarks do |t|
      t.references :task, null: false, foreign_key: true
      t.references :remarkable, polymorphic: true, null: false
      t.text :content

      t.timestamps
    end
  end
end
