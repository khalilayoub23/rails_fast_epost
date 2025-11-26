# frozen_string_literal: true

class AddOperationalIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :customers, :name, algorithm: :concurrently, if_not_exists: true
    add_index :messengers, :vehicle_type, algorithm: :concurrently, if_not_exists: true
    add_index :tasks, :created_at, algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :tasks, :created_at, if_exists: true, algorithm: :concurrently
    remove_index :messengers, :vehicle_type, if_exists: true, algorithm: :concurrently
    remove_index :customers, :name, if_exists: true, algorithm: :concurrently
  end
end
