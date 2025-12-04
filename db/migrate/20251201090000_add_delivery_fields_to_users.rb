class AddDeliveryFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :full_name
      t.string :phone
      t.text :address
      t.integer :user_type, default: 0, null: false, comment: "0=sender,1=lawyer,2=courier,3=recipient"
    end

    add_index :users, :user_type
  end
end
