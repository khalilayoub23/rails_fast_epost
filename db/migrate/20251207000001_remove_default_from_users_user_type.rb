class RemoveDefaultFromUsersUserType < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :user_type, from: 0, to: nil
  end
end
