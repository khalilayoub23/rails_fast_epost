class AddArchiveUntilDateToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :archive_until_date, :date
  end
end
