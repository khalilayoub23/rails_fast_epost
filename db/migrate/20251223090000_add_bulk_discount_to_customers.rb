class AddBulkDiscountToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :bulk_discount, :decimal, precision: 5, scale: 2
  end
end
