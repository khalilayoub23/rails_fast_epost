class ChangeTaskTypeToString < ActiveRecord::Migration[8.0]
  def up
    add_column :tasks, :task_type_new, :string, default: "court_filings", null: false

    execute <<~SQL
      UPDATE tasks
      SET task_type_new = CASE task_type
        WHEN 0 THEN 'court_filings'
        WHEN 1 THEN 'delivery_and_pickup'
        WHEN 2 THEN 'court_filings'
        WHEN 3 THEN 'document_retrieval_from_government_agencies'
        WHEN 4 THEN 'proof_of_delivery_pod'
        WHEN 5 THEN 'delivery_and_pickup'
        ELSE 'court_filings'
      END
    SQL

    remove_index :tasks, :task_type if index_exists?(:tasks, :task_type)
    remove_column :tasks, :task_type, :integer
    rename_column :tasks, :task_type_new, :task_type
    add_index :tasks, :task_type
  end

  def down
    add_column :tasks, :task_type_old, :integer, default: 1, null: false

    execute <<~SQL
      UPDATE tasks
      SET task_type_old = CASE task_type
        WHEN 'court_filings' THEN 0
        WHEN 'delivery_and_pickup' THEN 1
        WHEN 'document_retrieval_from_government_agencies' THEN 3
        WHEN 'proof_of_delivery_pod' THEN 4
        ELSE 1
      END
    SQL

    remove_index :tasks, :task_type if index_exists?(:tasks, :task_type)
    remove_column :tasks, :task_type, :string
    rename_column :tasks, :task_type_old, :task_type
    add_index :tasks, :task_type
  end
end
