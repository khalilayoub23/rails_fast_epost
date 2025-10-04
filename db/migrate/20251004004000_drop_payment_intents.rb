class DropPaymentIntents < ActiveRecord::Migration[8.0]
  def change
    drop_table :payment_intents, if_exists: true
  end
end
