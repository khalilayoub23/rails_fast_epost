class CreatePhones < ActiveRecord::Migration[8.0]
  def change
    create_table :phones do |t|
      t.references :carrier_id, null: false, foreign_key: true
      t.boolean :primary

      t.timestamps
    end
  end
end
