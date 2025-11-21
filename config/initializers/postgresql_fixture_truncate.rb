# frozen_string_literal: true

# Provides a fallback path when PostgreSQL refuses to delete fixture rows
# because referential integrity couldn't be disabled (lack of superuser).
module PostgresqlFixtureTruncate
  THREAD_KEY = :__postgresql_fixture_truncate_retry

  def create_fixtures(fixtures_directories, fixture_set_names, class_names = {}, config = ActiveRecord::Base)
    super
  rescue ActiveRecord::InvalidForeignKey => error
    raise unless postgresql_fk_violation?(config, error)
    raise if Thread.current[THREAD_KEY]

    Thread.current[THREAD_KEY] = true
    begin
      truncate_tables_for(fixtures_directories, fixture_set_names, class_names, config)
      super
    ensure
      Thread.current[THREAD_KEY] = false
    end
  end

  private

  def postgresql_fk_violation?(config, error)
    error.cause.is_a?(PG::ForeignKeyViolation) && config.connection.adapter_name == "PostgreSQL"
  rescue ActiveRecord::ActiveRecordError
    false
  end

  def truncate_tables_for(_fixtures_directories, fixture_set_names, class_names, config)
    tables = fixture_table_names_for(fixture_set_names, class_names, config)
    return if tables.empty?

    connection_pool = config.connection_pool
    connection_pool.with_connection do |conn|
      quoted_tables = tables.map { |table| conn.quote_table_name(table) }
      conn.execute("TRUNCATE TABLE #{quoted_tables.join(', ')} RESTART IDENTITY CASCADE")
    end

    clear_cached_fixtures(connection_pool, tables)
  end

  def fixture_table_names_for(fixture_set_names, class_names, config)
    fixture_set_names = Array(fixture_set_names).map(&:to_s)
    class_names = (class_names || {}).stringify_keys

    fixture_set_names.map do |fixture_name|
      klass = class_names[fixture_name]
      klass = klass.constantize if klass.is_a?(String)
      klass&.table_name || ActiveRecord::FixtureSet.default_fixture_table_name(fixture_name, config).to_s
    end.uniq
  end

  def clear_cached_fixtures(connection_pool, tables)
    cache = ActiveRecord::FixtureSet.cache_for_connection_pool(connection_pool)
    tables.each { |table| cache.delete(table) }
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::FixtureSet.singleton_class.prepend(PostgresqlFixtureTruncate)
end
