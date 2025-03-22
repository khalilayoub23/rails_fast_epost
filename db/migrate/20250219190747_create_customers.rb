class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name
      t.text :phones
      t.integer :category
      t.string :address
      t.string :email

      t.timestamps
    end
  end
end
