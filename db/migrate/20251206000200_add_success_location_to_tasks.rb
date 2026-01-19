class AddSuccessLocationToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :last_success_lat, :decimal, precision: 10, scale: 6
    add_column :tasks, :last_success_lng, :decimal, precision: 10, scale: 6
    add_column :tasks, :last_success_accuracy, :decimal, precision: 8, scale: 2
  end
end
