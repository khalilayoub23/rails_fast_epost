class MakeTasksCustomerOptional < ActiveRecord::Migration[8.0]
  def change
    change_column_null :tasks, :customer_id, true
  end
end
