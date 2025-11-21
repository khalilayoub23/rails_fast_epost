class ChangePhonesToPolymorphic < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :phones, :carriers

    if index_exists?(:phones, :carrier_id)
      remove_index :phones, name: "index_phones_on_carrier_id"
    end

    rename_column :phones, :carrier_id, :phoneable_id
    add_column :phones, :phoneable_type, :string

    execute <<~SQL.squish
      UPDATE phones SET phoneable_type = 'Carrier'
    SQL

    change_column_null :phones, :phoneable_id, false
    change_column_null :phones, :phoneable_type, false

    add_index :phones, %i[phoneable_type phoneable_id]
  end

  def down
    remove_index :phones, %i[phoneable_type phoneable_id]

    change_column_null :phones, :phoneable_type, true
    change_column_null :phones, :phoneable_id, true

    execute <<~SQL.squish
      UPDATE phones SET phoneable_type = NULL
    SQL

    remove_column :phones, :phoneable_type
    rename_column :phones, :phoneable_id, :carrier_id

    add_index :phones, :carrier_id
    add_foreign_key :phones, :carriers, on_delete: :cascade
  end
end
