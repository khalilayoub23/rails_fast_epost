class CreateFormTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :form_templates do |t|
      t.references :carrier_id, null: false, foreign_key: true
      t.references :customer_id, null: false, foreign_key: true

      t.timestamps
    end
  end
end
