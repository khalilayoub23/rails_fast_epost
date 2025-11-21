class AddPriorityToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :priority, :string, default: "normal", null: false
    add_index :tasks, :priority
  end
end
