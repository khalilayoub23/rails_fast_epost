class AddFailureHandlingToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :failed_attempts, :integer, null: false, default: 0
    add_column :tasks, :last_failure_note, :text
    add_column :tasks, :stored_until, :datetime
    add_column :tasks, :awaiting_customer_response, :boolean, null: false, default: false
  end
end
