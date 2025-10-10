require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should create user with valid attributes" do
    user = User.new(email: "test@example.com", password: "password123", role: "viewer")
    assert user.valid?
  end

  test "should require email" do
    user = User.new(password: "password123", role: "viewer")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require password" do
    user = User.new(email: "test@example.com", role: "viewer")
    assert_not user.valid?
  end

  test "should require valid role" do
    user = User.new(email: "test@example.com", password: "password123", role: "invalid")
    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "should default to viewer role" do
    user = User.create!(email: "test@example.com", password: "password123")
    assert_equal "viewer", user.role
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

  test "manager? should return false for viewer" do
    user = User.new(role: "viewer")
    assert_not user.manager?
  end

  test "viewer? should return true only for viewer" do
    viewer = User.new(role: "viewer")
    manager = User.new(role: "manager")
    assert viewer.viewer?
    assert_not manager.viewer?
  end
end
