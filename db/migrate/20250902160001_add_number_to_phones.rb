class AddNumberToPhones < ActiveRecord::Migration[8.0]
  def change
    add_column :phones, :number, :string
  end
end
