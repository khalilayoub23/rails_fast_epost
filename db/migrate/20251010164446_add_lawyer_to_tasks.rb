class AddLawyerToTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :tasks, :lawyer, null: true, foreign_key: true, index: true
  end
end
