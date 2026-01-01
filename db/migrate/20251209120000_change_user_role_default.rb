class ChangeUserRoleDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :role, from: "viewer", to: "sender"
  end

  def down
    change_column_default :users, :role, from: "sender", to: "viewer"
  end
end
