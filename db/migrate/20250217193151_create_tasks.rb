class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :customer_id, null: false, foreign_key: true
      t.references :carrier_id, null: false, foreign_key: true
      t.string :package_type
      t.string :start
      t.string :target
      t.string :failure_code
      t.datetime :delivery_time
      t.integer :status
      t.string :barcode
      t.string :filled_form_url

      t.timestamps
    end
  end
end
