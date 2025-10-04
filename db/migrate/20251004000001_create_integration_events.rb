class CreateIntegrationEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :integration_events do |t|
      t.string :provider, null: false
      t.jsonb :headers, null: false, default: {}
      t.jsonb :body, null: false, default: {}
      t.boolean :signature_valid, null: false, default: false
      t.string :status, null: false, default: "received"
      t.datetime :processed_at

      t.timestamps
    end

    add_index :integration_events, [ :provider, :created_at ]
  end
end
