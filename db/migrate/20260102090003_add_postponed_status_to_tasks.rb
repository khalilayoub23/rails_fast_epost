class AddPostponedStatusToTasks < ActiveRecord::Migration[8.0]
  def up
    # No database change needed: tasks.status is an integer enum.
    # The new :postponed value is added in the model enum mapping.
  end

  def down
    # No database change needed.
  end
end
