class CreateCarrierMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :carrier_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :carrier, null: false, foreign_key: true

      t.timestamps
    end

    add_index :carrier_memberships, [ :user_id, :carrier_id ], unique: true
  end
end
