class CreateRefunds < ActiveRecord::Migration[8.0]
  def change
    create_table :refunds do |t|
      t.references :payment, null: false, foreign_key: { to_table: :payments, on_delete: :cascade }
      t.string :provider, null: false
      t.string :refund_id
      t.integer :amount_cents
      t.string :currency
      t.string :reason
      t.string :status
      t.string :balance_transaction_id
      t.jsonb :raw, null: false, default: {}
      t.datetime :occurred_at

      t.timestamps
    end

    add_index :refunds, [ :provider, :refund_id ], unique: true, where: "refund_id IS NOT NULL"
    unless index_exists?(:refunds, :payment_id)
      add_index :refunds, :payment_id
    end
  end
end
