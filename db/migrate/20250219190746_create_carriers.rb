class CreateCarriers < ActiveRecord::Migration[8.0]
  def change
    create_table :carriers do |t|
      t.string :type
      t.string :name
      t.string :email
      t.string :address

      t.timestamps
    end
  end
end
