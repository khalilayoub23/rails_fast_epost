class CreateSenders < ActiveRecord::Migration[8.0]
  def change
    create_table :senders do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.text :address, null: false
      t.integer :sender_type, default: 0, null: false  # 0=individual, 1=business, 2=government

      # Business-specific fields (optional for individuals)
      t.string :company_name
      t.string :tax_id
      t.string :business_registration

      # Additional contact info
      t.string :secondary_phone
      t.string :website

      # Preferences
      t.jsonb :preferences, default: {}

      # Notes
      t.text :notes

      t.timestamps
    end

    add_index :senders, :email
    add_index :senders, :sender_type
    add_index :senders, :company_name
  end
end
