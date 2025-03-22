class CreateCostCalcs < ActiveRecord::Migration[8.0]
  def change
    create_table :cost_calcs do |t|
      t.references :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
