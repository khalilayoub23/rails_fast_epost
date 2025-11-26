# frozen_string_literal: true

require "securerandom"

class HardenTaskBarcodesAndStatus < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  class Task < ActiveRecord::Base
    self.table_name = "tasks"
  end

  def up
    backfill_missing_statuses
    resolve_duplicate_barcodes
    backfill_missing_barcodes

    change_column_default :tasks, :status, from: nil, to: 0
    change_column_null :tasks, :status, false
    change_column_null :tasks, :barcode, false

    add_index :tasks, :barcode, unique: true, algorithm: :concurrently, if_not_exists: true
    add_index :tasks, :status, algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :tasks, :status, if_exists: true, algorithm: :concurrently
    remove_index :tasks, :barcode, if_exists: true, algorithm: :concurrently

    change_column_null :tasks, :barcode, true
    change_column_null :tasks, :status, true
    change_column_default :tasks, :status, from: 0, to: nil
  end

  private

  def backfill_missing_statuses
    Task.where(status: nil).update_all(status: 0)
  end

  def backfill_missing_barcodes
    Task.where(barcode: [ nil, "" ]).find_each do |task|
      task.update_columns(barcode: generate_unique_barcode)
    end
  end

  def resolve_duplicate_barcodes
    Task.where.not(barcode: [ nil, "" ])
        .group(:barcode)
        .having("COUNT(*) > 1")
        .pluck(:barcode)
        .each do |duplicate_code|
      Task.where(barcode: duplicate_code).order(:id).offset(1).find_each do |task|
        task.update_columns(barcode: generate_unique_barcode)
      end
    end
  end

  def generate_unique_barcode
    loop do
      code = "TSK#{SecureRandom.hex(5).upcase}"
      break code unless Task.exists?(barcode: code)
    end
  end
end
