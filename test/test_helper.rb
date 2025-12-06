ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "action_mailer/test_helper"
require "base64"
require "securerandom"

if Rails.env.test?
  module SafeReferentialIntegrity
    def disable_referential_integrity
      transaction(requires_new: true) do
        execute("SET CONSTRAINTS ALL DEFERRED")
        yield
      end
    rescue StandardError
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

    if names.any? { |n| %w[remarks carrier_payouts payments].include?(n.to_s) }
      names |= %w[tasks users customers carriers senders lawyers messengers]
    end

    if names.any? { |n| n.to_s == "tasks" }
      names |= %w[customers carriers senders messengers lawyers]
    end

    priority = lambda do |name|
      case name.to_s
      when "carriers" then 0
      when "customers" then 1
      when "senders" then 2
      when "messengers" then 3
      when "lawyers" then 4
      when "users" then 5
      when "tasks" then 6
      when "payments" then 7
      when "carrier_payouts" then 8
      else 10
      end
    end

    names.sort_by(&priority).flat_map do |name|
      super(fixtures_directories, [ name ], class_names, config)
    end
  end
end

ActiveRecord::FixtureSet.singleton_class.prepend(SequentialFixtureLoader)

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper
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
    setup do
      clear_enqueued_jobs
      clear_performed_jobs
    end
  end
end

module SignatureFixtureHelpers
  def attach_signature_fixture(user, fixture_name: "signature.png")
    File.open(file_fixture(fixture_name)) do |io|
      user.saved_signature.attach(io: io, filename: fixture_name, content_type: "image/png")
    end
  end

  def ensure_signature_fixture(user)
    attach_signature_fixture(user) unless user.saved_signature.attached?
  end

  def fixture_signature_data_uri(fixture_name = "signature.png")
    payload = File.binread(file_fixture(fixture_name))
    "data:image/png;base64,#{Base64.strict_encode64(payload)}"
  end
end

module DeliveryTestHelper
  def build_delivery!(case_number: "CASE-#{SecureRandom.alphanumeric(6).upcase}")
    sender = users(:lawyer_user)
    courier = users(:courier_user)
    recipient = users(:recipient_user)
    ensure_signature_fixture(sender)
    ensure_signature_fixture(courier)

    Delivery.create!(
      case_number: case_number,
      sender: sender,
      courier: courier,
      recipient: recipient,
      notes: "Test delivery"
    )
  end
end

ActiveSupport::TestCase.include(SignatureFixtureHelpers)
ActiveSupport::TestCase.include(DeliveryTestHelper)

# Devise test helpers for integration and controller tests
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
