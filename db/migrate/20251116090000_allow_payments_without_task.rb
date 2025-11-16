class AllowPaymentsWithoutTask < ActiveRecord::Migration[7.1]
  def change
    change_column_null :payments, :task_id, true
  end
end
