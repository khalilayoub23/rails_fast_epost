# frozen_string_literal: true

class EnforceSenderAndCustomerEmailUniqueness < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  class Sender < ActiveRecord::Base
    self.table_name = "senders"
  end

  class Customer < ActiveRecord::Base
    self.table_name = "customers"
  end

  def up
    dedupe_senders
    dedupe_customers

    remove_index :senders, :email if index_exists?(:senders, :email, unique: false)
    add_index :senders, :email, unique: true, algorithm: :concurrently, if_not_exists: true

    add_index :customers, :email, unique: true, algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :customers, :email, if_exists: true, algorithm: :concurrently
    remove_index :senders, :email, if_exists: true, algorithm: :concurrently
    add_index :senders, :email unless index_exists?(:senders, :email)
  end

  private

  def dedupe_senders
    duplicate_email_scope(Sender).each do |email|
      reassign_duplicate_records(Sender, email)
    end
  end

  def dedupe_customers
    duplicate_email_scope(Customer).each do |email|
      reassign_duplicate_records(Customer, email)
    end
  end

  def duplicate_email_scope(model)
    model.where.not(email: [ nil, "" ])
         .group("LOWER(email)")
         .having("COUNT(*) > 1")
         .pluck(Arel.sql("LOWER(email)"))
  end

  def reassign_duplicate_records(model, normalized_email)
        model.where("LOWER(email) = ?", normalized_email)
          .order(:id)
          .offset(1)
          .find_each do |record|
      record.update_columns(email: deduped_email(record.email, record.id))
    end
  end

  def deduped_email(original_email, record_id)
    local, domain = original_email.split("@", 2)
    return "#{original_email}-dup#{record_id}" unless domain

    "#{local}+dup#{record_id}@#{domain}"
  end
end
