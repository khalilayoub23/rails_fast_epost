class CreateSignatureEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_events do |t|
      t.references :delivery, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false
      t.integer :action, null: false, default: 0
      t.string :signature_hash
      t.string :ip_address
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :signature_events, [:delivery_id, :role]
    add_index :signature_events, :signature_hash
    add_index :signature_events, :created_at
  end
end
