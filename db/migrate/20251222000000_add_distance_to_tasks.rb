class AddDistanceToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :distance, :decimal, precision: 10, scale: 2
    add_index :tasks, :distance
  end
end
