class CreatePaymentIntents < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_intents do |t|
      t.string  :provider, null: false
      t.string  :external_id
      t.string  :status, null: false, default: "created"
      t.integer :amount_cents, null: false
      t.string  :currency, null: false, default: "USD"
      t.bigint  :task_id
      t.bigint  :customer_id
      t.string  :payment_url
      t.jsonb   :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :payment_intents, [ :provider, :external_id ], unique: true, where: "external_id IS NOT NULL", name: "index_payment_intents_on_provider_and_external_id"
    add_index :payment_intents, :task_id
    add_index :payment_intents, :customer_id

    add_foreign_key :payment_intents, :tasks, on_delete: :nullify
    add_foreign_key :payment_intents, :customers, on_delete: :nullify
  end
end
