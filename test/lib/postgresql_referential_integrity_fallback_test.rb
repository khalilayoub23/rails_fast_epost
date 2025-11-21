require "test_helper"

class PostgresqlReferentialIntegrityFallbackTest < Minitest::Test
  class FakeAdapter
    prepend PostgresqlReferentialIntegrityFallback

    def disable_referential_integrity(*)
      raise permission_error
    end

    private

    def permission_error
      ActiveRecord::StatementInvalid.new("permission denied").tap do |error|
        cause = PG::InsufficientPrivilege.new("permission denied")
        error.define_singleton_method(:cause) { cause }
      end
    end
  end

  def test_falls_back_to_running_block_when_permissions_missing
    adapter = FakeAdapter.new
    executed = false

    adapter.disable_referential_integrity { executed = true }

    assert executed
  end

  def test_skips_foreign_key_validation_when_permissions_missing
    fake_fixture_set = Class.new do
      def self.check_all_foreign_keys_valid!(*)
        error = ActiveRecord::StatementInvalid.new("permission denied")
        cause = PG::InsufficientPrivilege.new("permission denied")
        error.define_singleton_method(:cause) { cause }
        raise error
      end
    end

    fake_fixture_set.singleton_class.prepend(PostgresqlForeignKeyValidationFallback)

    assert_equal [], fake_fixture_set.check_all_foreign_keys_valid!
  end
end
