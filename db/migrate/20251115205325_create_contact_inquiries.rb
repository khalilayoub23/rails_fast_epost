class CreateContactInquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_inquiries do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :service
      t.text :message
      t.integer :status

      t.timestamps
    end
  end
end
