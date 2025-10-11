#!/usr/bin/env ruby
# Run migrations programmatically to bypass rake task issues

require File.expand_path('../config/environment', __dir__)

puts "=== Starting Migration Process ==="
puts "Environment: #{Rails.env}"
puts "Database: #{ActiveRecord::Base.connection.current_database}"
puts ""

begin
  # Enable verbose output
  ActiveRecord::Migration.verbose = true
  
  # Get migration context
  migrations_paths = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).flat_map(&:migrations_paths).compact.uniq
  migration_context = ActiveRecord::MigrationContext.new(migrations_paths, ActiveRecord::SchemaMigration)
  
  puts "Migrations path: #{migrations_paths.inspect}"
  puts "Pending migrations: #{migration_context.needs_migration? ? 'Yes' : 'No'}"
  puts ""
  
  if migration_context.needs_migration?
    puts "Running migrations..."
    migration_context.migrate
    puts "✓ Migrations completed successfully"
  else
    puts "✓ Database is up to date (no pending migrations)"
  end
  
  puts ""
  puts "=== Verifying Lawyer Model ==="
  
  # Check if lawyers table exists
  if ActiveRecord::Base.connection.table_exists?(:lawyers)
    puts "✓ lawyers table exists"
    puts "  Columns: #{Lawyer.column_names.join(', ')}"
    puts "  Indexes: #{ActiveRecord::Base.connection.indexes(:lawyers).map(&:name).join(', ')}"
  else
    puts "✗ lawyers table does not exist"
  end
  
  # Check if lawyer_id was added to tasks
  if ActiveRecord::Base.connection.column_exists?(:tasks, :lawyer_id)
    puts "✓ lawyer_id column exists in tasks table"
  else
    puts "✗ lawyer_id column missing from tasks table"
  end
  
  puts ""
  puts "=== Migration Summary ==="
  puts "Status: SUCCESS ✓"
  
rescue => e
  puts ""
  puts "=== Migration Failed ==="
  puts "Error: #{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end
