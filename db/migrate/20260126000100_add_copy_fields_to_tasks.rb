class AddCopyFieldsToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :case_file_number, :string
    add_column :tasks, :delivery_medium, :string
  end
end
