class AddTaskTypeToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :task_type, :integer, default: 1, null: false
    add_index :tasks, :task_type
  end
end
