class AddTaskReferenceToForms < ActiveRecord::Migration[7.1]
  def change
    return if column_exists?(:forms, :task_id)

    add_reference :forms, :task, foreign_key: true
  end
end
