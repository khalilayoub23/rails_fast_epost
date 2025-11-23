ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

if Rails.env.test?
  module SafeReferentialIntegrity
    def disable_referential_integrity
      transaction(requires_new: true) { yield }
    end
  end

  apply_safe_referential_integrity_patch = lambda do
    adapter = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    return if adapter < SafeReferentialIntegrity

    adapter.prepend(SafeReferentialIntegrity)
  end

  if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    apply_safe_referential_integrity_patch.call
  else
    ActiveSupport.on_load(:active_record) { apply_safe_referential_integrity_patch.call }
  end
end

class FixtureDependencySorter
  def initialize(tables, connection = ActiveRecord::Base.connection)
    @tables = tables
    @connection = connection
    @dependencies = Hash.new { |hash, key| hash[key] = [] }
    build_dependencies
  end

  def sorted
    result = []
    marks = {}

    visit = lambda do |table|
      return if marks[table] == :permanent
      raise "Circular dependency detected for fixtures: #{table}" if marks[table] == :temporary

      marks[table] = :temporary
      @dependencies[table].each { |dep| visit.call(dep) }
      marks[table] = :permanent
      result << table
    end

    @tables.each { |table| visit.call(table) }
    result
  end

  private

  def build_dependencies
    @tables.each do |table|
      @connection.foreign_keys(table).each do |fk|
        target = fk.to_table
        @dependencies[table] << target if @tables.include?(target)
      end
    end
  end
end

module SequentialFixtureLoader
  def create_fixtures(fixtures_directories, fixture_set_names, class_names = {}, config = ActiveRecord::Base)
    names = Array(fixture_set_names)
    return super if names.length <= 1

    names.flat_map do |name|
      super(fixtures_directories, [ name ], class_names, config)
    end
  end
end

ActiveRecord::FixtureSet.singleton_class.prepend(SequentialFixtureLoader)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    system_driver = ENV["SYSTEM_TEST_DRIVER"]
    parallel_env = ENV["PARALLEL_WORKERS"]
    parallel_workers = if parallel_env && !parallel_env.empty?
      [ parallel_env.to_i, 1 ].max
    elsif system_driver && !system_driver.empty? && system_driver != "rack_test"
      1
    else
      :number_of_processors
    end

    parallelize(workers: parallel_workers)

    self.fixture_paths = [ Rails.root.join("test/fixtures") ] if fixture_paths.blank?
    fixture_files = Dir[Rails.root.join("test/fixtures/*.yml")]
    fixture_tables = fixture_files.map { |path| File.basename(path, ".yml") }
    ordered_tables = FixtureDependencySorter.new(fixture_tables).sorted
    self.fixture_table_names = ordered_tables
    setup_fixture_accessors(ordered_tables)

    # Add more helper methods to be used by all tests here...
  end
end

# Devise test helpers for integration and controller tests
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
