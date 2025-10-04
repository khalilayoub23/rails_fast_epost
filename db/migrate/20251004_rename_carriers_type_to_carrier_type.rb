class RenameCarriersTypeToCarrierType < ActiveRecord::Migration[8.0]
  def up
    if column_exists?(:carriers, :type)
      rename_column :carriers, :type, :carrier_type
    end
  end

  def down
    if column_exists?(:carriers, :carrier_type)
      rename_column :carriers, :carrier_type, :type
    end
  end
end
