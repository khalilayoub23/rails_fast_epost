class AddRefundMetadataToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :refund_id, :string
    add_column :payments, :refund_status, :string
    add_column :payments, :refund_balance_transaction_id, :string
    add_column :payments, :refunded_at, :datetime

    add_index :payments, :refund_id
  end
end
