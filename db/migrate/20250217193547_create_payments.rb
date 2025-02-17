class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.integer :category
      t.references :task_id, null: false, foreign_key: true
      t.integer :payable_id
      t.string :payable_type
      t.integer :payment_type
      t.date :interval_start
      t.date :interval_end

      t.timestamps
    end
  end
end
