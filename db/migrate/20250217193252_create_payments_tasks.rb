class CreatePaymentsTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :payments_tasks do |t|
      t.references :task_id, null: false, foreign_key: true
      t.references :payment_id, null: false, foreign_key: true

      t.timestamps
    end
  end
end
