require "test_helper"

class UserTest < ActiveSupport::TestCase
  PERSISTENCE_EMAIL = "persistence@example.com"
  PERSISTENCE_CREATE_EMAIL = "persistence-create@example.com"

  test "should create user with valid attributes" do
    user = User.new(email: "test@example.com", password: "password123", role: "sender")
    assert user.valid?
  end

  test "persists a valid user" do
    assert_difference("User.count", 1) do
      user = User.create!(email: PERSISTENCE_CREATE_EMAIL, password: "password123", role: "sender")
      assert user.persisted?
    end
  end

  test "finds persisted persistence user" do
    found = User.find_by(email: PERSISTENCE_EMAIL)
    assert found, "expected to find #{PERSISTENCE_EMAIL}"
    puts "Found persisted user ##{found.id} #{found.email}"
  end

  test "should require email" do
    user = User.new(password: "password123", role: "sender")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require password" do
    user = User.new(email: "test@example.com", role: "sender")
    assert_not user.valid?
  end

  test "should require valid role" do
    assert_raises(ArgumentError) do
      User.new(email: "test@example.com", password: "password123", role: "invalid")
    end
  end

  test "should default to sender role" do
    user = User.create!(email: "test@example.com", password: "password123")
    assert_equal "sender", user.role
  end

  test "admin? should return true for admin" do
    user = User.new(role: "admin")
    assert user.admin?
  end

  test "admin? should return false for non-admin" do
    user = User.new(role: "manager")
    assert_not user.admin?
  end

  test "manager? should return true for manager and admin" do
    manager = User.new(role: "manager")
    admin = User.new(role: "admin")
    assert manager.manager?
    assert admin.manager?
  end

  test "manager? should return true for operations manager" do
    ops = User.new(role: "operations_manager")
    assert ops.manager?
  end

  test "operations_manager? helper" do
    ops = User.new(role: "operations_manager")
    admin = User.new(role: "admin")
    viewer = User.new(role: "sender")

    assert ops.operations_manager?
    assert admin.operations_manager?
    assert_not viewer.operations_manager?
  end

  test "manager? should return false for sender" do
    user = User.new(role: "sender")
    assert_not user.manager?
  end

  test "viewer? reflects sender, lawyer, and ecommerce roles" do
    sender = User.new(role: "sender")
    lawyer = User.new(role: "lawyer")
    ecommerce = User.new(role: "ecommerce_seller")
    manager = User.new(role: "manager")

    assert sender.viewer?
    assert lawyer.viewer?
    assert ecommerce.viewer?
    assert_not manager.viewer?
  end

  test "should default to sender role and type on initialize" do
    user = User.new
    assert_equal "sender", user.role
    assert_equal "sender", user.user_type
  end
end
