class CreateDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :deliveries do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :courier, null: false, foreign_key: { to_table: :users }
      t.string :case_number, null: false
      t.text :notes
      t.integer :status, null: false, default: 0
      t.jsonb :signature_data, null: false, default: {}
      t.datetime :completed_at

      t.timestamps
    end

    add_index :deliveries, :case_number, unique: true
    add_index :deliveries, :status
    add_index :deliveries, :completed_at
    add_index :deliveries, :signature_data, using: :gin
  end
end
