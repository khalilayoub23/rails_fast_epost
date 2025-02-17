class CreateForms < ActiveRecord::Migration[8.0]
  def change
    create_table :forms do |t|
      t.string :address
      t.references :customer_id, null: false, foreign_key: true
      t.string :form_default_url

      t.timestamps
    end
  end
end
