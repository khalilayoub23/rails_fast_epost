class AddDoorAffixFieldsToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :door_affix_authorized, :boolean, default: false, null: false
    add_column :tasks, :door_affix_completed, :boolean, default: false, null: false
    add_column :tasks, :door_affix_completed_at, :datetime
  end
end