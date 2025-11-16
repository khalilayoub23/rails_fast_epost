class AddAdminNotesToContactInquiries < ActiveRecord::Migration[8.0]
  def change
    add_column :contact_inquiries, :admin_notes, :text
  end
end
