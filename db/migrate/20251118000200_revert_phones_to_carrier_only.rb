class RevertPhonesToCarrierOnly < ActiveRecord::Migration[8.0]
  def up
    if index_exists?(:phones, [:phoneable_type, :phoneable_id])
      remove_index :phones, [:phoneable_type, :phoneable_id]
    end

    execute <<~SQL.squish
      DELETE FROM phones WHERE phoneable_type IS NOT NULL AND phoneable_type != 'Carrier'
    SQL

    rename_column :phones, :phoneable_id, :carrier_id
    remove_column :phones, :phoneable_type

    change_column_null :phones, :carrier_id, false

    add_index :phones, :carrier_id
    add_foreign_key :phones, :carriers, on_delete: :cascade
  end

  def down
    remove_foreign_key :phones, :carriers if foreign_key_exists?(:phones, :carriers)
    remove_index :phones, :carrier_id if index_exists?(:phones, :carrier_id)

    add_column :phones, :phoneable_type, :string
    rename_column :phones, :carrier_id, :phoneable_id

    execute <<~SQL.squish
      UPDATE phones SET phoneable_type = 'Carrier'
    SQL

    change_column_null :phones, :phoneable_id, false
    change_column_null :phones, :phoneable_type, false

    add_index :phones, [:phoneable_type, :phoneable_id]
  end
end
