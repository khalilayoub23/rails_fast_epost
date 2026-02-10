class AddArchiveFieldsToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :archive_item_type, :string
    add_column :tasks, :archive_quantity, :integer
    add_column :tasks, :archive_duration_days, :integer
  end
end
