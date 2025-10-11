class CreateMessengers < ActiveRecord::Migration[8.0]
  def change
    create_table :messengers do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone, null: false

      # Status: 0=available, 1=busy, 2=offline
      t.integer :status, default: 0, null: false

      # Vehicle: 0=van, 1=motorcycle, 2=bicycle, 3=car, 4=truck
      t.integer :vehicle_type
      t.string :license_plate

      # Credentials
      t.string :license_number  # Driver's license
      t.string :employee_id     # Company employee ID

      # Performance metrics
      t.integer :total_deliveries, default: 0
      t.float :on_time_rate, default: 0.0

      # Location tracking (JSON: {lat, lng, updated_at})
      t.jsonb :current_location, default: {}

      # Working hours (JSON: {monday: "9-17", tuesday: "9-17", ...})
      t.jsonb :working_hours, default: {}

      # Carrier association (optional - can be independent)
      t.references :carrier, foreign_key: true

      # Notes
      t.text :notes

      t.timestamps
    end

    add_index :messengers, :status
    # carrier_id index already created by t.references
    add_index :messengers, :employee_id
  end
end
