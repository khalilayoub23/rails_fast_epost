require "test_helper"

class DefaultAccountsProvisionerTest < ActiveSupport::TestCase
  setup do
    @provisioner = DefaultAccountsProvisioner.new
    @password = ENV.fetch("DEFAULT_USER_PASSWORD", "password")
  end

  test "creates default account when email is unused" do
    email = "demo-admin-#{SecureRandom.hex(4)}@example.com"

    assert_difference -> { User.where(email: email).count }, 1 do
      create_default_account(email: email, role: "admin", fallback_email: "admin@example.com")
    end

    user = User.find_by(email: email)
    assert_equal "admin", user.role
    assert user.valid_password?(@password)
  end

  test "does not override existing user with same role" do
    existing = User.create!(
      email: "custom-viewer-#{SecureRandom.hex(3)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "viewer"
    )

    default_email = "viewer-demo-#{SecureRandom.hex(3)}@example.com"

    assert_difference("User.count", 1) do
      create_default_account(email: default_email, role: "viewer", fallback_email: nil)
    end

    assert_equal existing.email, existing.reload.email
    assert User.find_by(email: default_email)
  end

  test "relabels fallback account to desired email" do
    fallback_email = "ops-fallback-#{SecureRandom.hex(3)}@example.com"
    user = User.create!(
      email: fallback_email,
      password: "password123",
      password_confirmation: "password123",
      role: "operations_manager"
    )

    desired_email = "ops-updated-#{SecureRandom.hex(3)}@example.com"

    assert_no_difference("User.count") do
      create_default_account(email: desired_email, role: "operations_manager", fallback_email: fallback_email)
    end

    assert_equal desired_email, user.reload.email
  end

  private

  def create_default_account(email:, role:, fallback_email:)
    @provisioner.send(
      :ensure_account,
      email: email,
      fallback_email: fallback_email,
      role: role
    )
  end
end
