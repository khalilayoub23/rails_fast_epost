class CreateCarrierPayouts < ActiveRecord::Migration[8.0]
  def change
    create_table :carrier_payouts do |t|
      t.references :carrier, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.integer :amount_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.string :status, null: false, default: "pending"
      t.datetime :due_at
      t.datetime :paid_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :carrier_payouts, [ :carrier_id, :task_id ], unique: true
    add_index :carrier_payouts, :status
  end
end
