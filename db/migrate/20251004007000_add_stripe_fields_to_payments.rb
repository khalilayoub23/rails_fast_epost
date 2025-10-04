class AddStripeFieldsToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :stripe_customer_id, :string
    add_column :payments, :payment_intent_id, :string
    add_column :payments, :checkout_session_id, :string
    add_column :payments, :charge_id, :string
    add_column :payments, :refunded_amount_cents, :integer
    add_column :payments, :refund_reason, :string

    add_index :payments, :payment_intent_id
    add_index :payments, :checkout_session_id
    add_index :payments, :charge_id
  end
end
