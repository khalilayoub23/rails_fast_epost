class AddSenderAndMessengerToTasks < ActiveRecord::Migration[8.0]
  def change
    # Add sender reference (required - every task must have a sender)
    add_reference :tasks, :sender, foreign_key: true

    # Add messenger reference (optional - assigned when task is accepted)
    add_reference :tasks, :messenger, foreign_key: true

    # Add pickup details (sender's location and time preferences)
    add_column :tasks, :pickup_address, :text
    add_column :tasks, :pickup_contact_phone, :string
    add_column :tasks, :pickup_notes, :text
    add_column :tasks, :requested_pickup_time, :datetime

    # Indexes already created by add_reference above
  end
end
