class AddCollectionAmountToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :collection_amount, :decimal, precision: 10, scale: 2
    add_column :tasks, :collection_currency, :string, default: "ILS"
    add_index :tasks, :collection_amount
  end
end