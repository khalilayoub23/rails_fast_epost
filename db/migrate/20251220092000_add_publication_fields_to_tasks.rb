class AddPublicationFieldsToTasks < ActiveRecord::Migration[8.0]
  class Task < ActiveRecord::Base
    self.table_name = "tasks"
  end

  def change
    add_reference :tasks, :created_by, foreign_key: { to_table: :users }, index: true
    add_column :tasks, :published, :boolean, default: false, null: false
    add_column :tasks, :published_at, :datetime
    add_index :tasks, :published

    reversible do |dir|
      dir.up do
        Task.reset_column_information
        Task.update_all("published = TRUE, published_at = created_at")
      end
    end
  end
end
