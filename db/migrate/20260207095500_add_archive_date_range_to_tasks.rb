class AddArchiveDateRangeToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :archive_from_date, :date
    add_column :tasks, :archive_to_date, :date
  end
end
