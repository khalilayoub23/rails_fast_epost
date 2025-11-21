# frozen_string_literal: true

# PostgreSQL requires superuser privileges to disable referential integrity.
# In CI/dev containers we often lack those privileges, so we gracefully fall
# back to running the fixture load without temporarily disabling constraints.
module PostgresqlReferentialIntegrityFallback
  def disable_referential_integrity(&block)
    super
  rescue ActiveRecord::StatementInvalid => e
    if e.cause.is_a?(PG::InsufficientPrivilege)
      Rails.logger.warn("[PostgreSQL] Skipping referential integrity disable: #{e.cause.message}")
      block&.call
    else
      raise
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgresqlReferentialIntegrityFallback)

  module PostgresqlForeignKeyValidationFallback
    def check_all_foreign_keys_valid!(*args)
      super
    rescue ActiveRecord::StatementInvalid => e
      handle_pg_insufficient_privilege(e) || raise
    rescue RuntimeError => e
      statement_invalid = e.cause
      raise unless statement_invalid.is_a?(ActiveRecord::StatementInvalid)

      handle_pg_insufficient_privilege(statement_invalid) || raise
    end

    private

    def handle_pg_insufficient_privilege(error)
      return unless error.cause.is_a?(PG::InsufficientPrivilege)

      Rails.logger.warn("[PostgreSQL] Skipping foreign key validation: #{error.cause.message}")
      []
    end
  end

  ActiveRecord::FixtureSet.singleton_class.prepend(PostgresqlForeignKeyValidationFallback)
end
