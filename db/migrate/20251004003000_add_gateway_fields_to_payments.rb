class AddGatewayFieldsToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :provider, :string
    add_column :payments, :external_id, :string
    add_column :payments, :gateway_status, :string, default: "created", null: false
    add_column :payments, :amount_cents, :integer
    add_column :payments, :currency, :string, default: "USD"
    add_column :payments, :payment_url, :string
    add_column :payments, :metadata, :jsonb, default: {}, null: false

    add_index :payments, [ :provider, :external_id ], unique: true, where: "external_id IS NOT NULL", name: "index_payments_on_provider_and_external_id"
  end
end
