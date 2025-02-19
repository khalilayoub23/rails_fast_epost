class CreatePreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :preferences do |t|
      t.references :carrier, null: false, foreign_key: true
      t.text :bank_account
      t.string :avatar
      t.integer :background_mode

      t.timestamps
    end
  end
end
