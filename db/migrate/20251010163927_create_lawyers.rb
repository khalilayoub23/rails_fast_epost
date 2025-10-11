class CreateLawyers < ActiveRecord::Migration[8.0]
  def change
    create_table :lawyers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.string :license_number, null: false
      t.integer :specialization, default: 0, null: false
      t.string :bar_association
      t.jsonb :certifications, default: {}
      t.text :notes
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :lawyers, :email, unique: true
    add_index :lawyers, :license_number, unique: true
    add_index :lawyers, :active
    add_index :lawyers, :specialization
  end
end
