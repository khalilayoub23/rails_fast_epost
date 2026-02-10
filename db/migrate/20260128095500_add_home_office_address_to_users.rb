class AddHomeOfficeAddressToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :home_address, :string
    add_column :users, :office_address, :string
  end
end