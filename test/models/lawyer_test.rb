require "test_helper"

class LawyerTest < ActiveSupport::TestCase
  def setup
    @lawyer = lawyers(:lawyer_one)
  end

  # Validation Tests
  test "should be valid with valid attributes" do
    assert @lawyer.valid?
  end

  test "should require name" do
    @lawyer.name = nil
    assert_not @lawyer.valid?
    assert_includes @lawyer.errors[:name], "can't be blank"
  end

  test "should require email" do
    @lawyer.email = nil
    assert_not @lawyer.valid?
    assert_includes @lawyer.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    invalid_emails = %w[user@.com @example.com plaintext user@]
    invalid_emails.each do |invalid_email|
      @lawyer.email = invalid_email
      assert_not @lawyer.valid?, "#{invalid_email} should be invalid"
    end

    valid_emails = %w[user@example.com USER@foo.COM first.last@foo.jp]
    valid_emails.each do |valid_email|
      @lawyer.email = valid_email
      assert @lawyer.valid?, "#{valid_email} should be valid"
    end
  end

  test "validates email uniqueness case-insensitively" do
    original_lawyer = lawyers(:lawyer_one)
    duplicate_lawyer = Lawyer.new(
      name: "Test Lawyer",
      email: original_lawyer.email.upcase,
      phone: "+1234567890",
      license_number: "LIC999999",
      specialization: :customs
    )
    assert_not duplicate_lawyer.valid?
    assert_includes duplicate_lawyer.errors[:email], "has already been taken"
  end

  test "should require phone" do
    @lawyer.phone = nil
    assert_not @lawyer.valid?
    assert_includes @lawyer.errors[:phone], "can't be blank"
  end

  test "should require license number" do
    @lawyer.license_number = nil
    assert_not @lawyer.valid?
    assert_includes @lawyer.errors[:license_number], "can't be blank"
  end

  test "should require unique license number" do
    duplicate_lawyer = @lawyer.dup
    duplicate_lawyer.email = "different@example.com"
    assert_not duplicate_lawyer.valid?
    assert_includes duplicate_lawyer.errors[:license_number], "has already been taken"
  end

  test "should require specialization" do
    @lawyer.specialization = nil
    assert_not @lawyer.valid?
    assert_includes @lawyer.errors[:specialization], "can't be blank"
  end

  # Association Tests
  test "should have many tasks" do
    assert_respond_to @lawyer, :tasks
  end

  test "should have many customers through tasks" do
    assert_respond_to @lawyer, :customers
  end

  test "should destroy associated tasks when destroyed with dependent nullify" do
    # Create a task associated with the lawyer
    task = tasks(:task_one)
    task.update(lawyer: @lawyer)

    assert_equal @lawyer, task.lawyer

    # Destroy the lawyer
    @lawyer.destroy

    # Task should still exist but lawyer_id should be nil
    task.reload
    assert_nil task.lawyer_id
  end

  # Enum Tests
  test "should have specialization enum" do
    assert_respond_to Lawyer, :specializations
    assert_includes Lawyer.specializations.keys, "customs"
    assert_includes Lawyer.specializations.keys, "international_trade"
    assert_includes Lawyer.specializations.keys, "contract"
  end

  test "should allow valid specializations" do
    valid_specializations = %i[customs international_trade contract corporate immigration intellectual_property litigation general_practice]
    valid_specializations.each do |spec|
      @lawyer.specialization = spec
      assert @lawyer.valid?, "#{spec} should be a valid specialization"
    end
  end

  # Scope Tests
  test "active scope should return only active lawyers" do
    active_lawyers = Lawyer.active
    assert active_lawyers.all?(&:active?)
    assert_includes active_lawyers, @lawyer
  end

  test "inactive scope should return only inactive lawyers" do
    inactive_lawyer = lawyers(:lawyer_five)
    inactive_lawyers = Lawyer.inactive
    assert inactive_lawyers.all? { |l| !l.active? }
    assert_includes inactive_lawyers, inactive_lawyer
  end

  test "by_specialization scope should filter by specialization" do
    customs_lawyers = Lawyer.by_specialization(:customs)
    assert customs_lawyers.all? { |l| l.specialization == "customs" }
  end

  # Instance Method Tests
  test "full_contact should return formatted contact string" do
    expected = "#{@lawyer.name} - #{@lawyer.email} - #{@lawyer.phone}"
    assert_equal expected, @lawyer.full_contact
  end

  test "display_name should return name with specialization" do
    expected = "#{@lawyer.name} (#{@lawyer.specialization.titleize})"
    assert_equal expected, @lawyer.display_name
  end

  test "activate! should set active to true" do
    inactive_lawyer = lawyers(:lawyer_five)
    assert_not inactive_lawyer.active?

    inactive_lawyer.activate!
    assert inactive_lawyer.active?
  end

  test "deactivate! should set active to false" do
    assert @lawyer.active?

    @lawyer.deactivate!
    assert_not @lawyer.active?
  end

  test "add_certification should add certification to certifications hash" do
    @lawyer.add_certification("New Certification", "2024", "Test Authority")

    @lawyer.reload
    assert @lawyer.certifications.key?("New Certification")
    assert_equal "2024", @lawyer.certifications["New Certification"]["date"]
    assert_equal "Test Authority", @lawyer.certifications["New Certification"]["issuer"]
  end

  test "certification_list should return array of certification names" do
    lawyer = lawyers(:lawyer_one)
    list = lawyer.certification_list
    assert_instance_of Array, list
    assert list.is_a?(Array)
  end

  test "certification_list should return empty array for empty certifications" do
    lawyer = lawyers(:lawyer_three)
    assert_equal [], lawyer.certification_list
  end

  # JSONB Certifications Tests
  test "should handle JSONB certifications field" do
    lawyer = Lawyer.create!(
      name: "Test Lawyer",
      email: "test@example.com",
      phone: "+1234567890",
      license_number: "TEST-001",
      specialization: :customs,
      certifications: [
        { name: "Cert 1", issuer: "Authority 1", year: 2020 },
        { name: "Cert 2", issuer: "Authority 2", year: 2021 }
      ],
      active: true
    )

    assert_equal 2, lawyer.certifications.size
    assert_equal "Cert 1", lawyer.certifications[0]["name"]
    assert_equal 2021, lawyer.certifications[1]["year"]
  end

  test "should default certifications to empty hash" do
    lawyer = Lawyer.new(
      name: "New Lawyer",
      email: "new@example.com",
      phone: "+1234567890",
      license_number: "NEW-001",
      specialization: :customs
    )

    assert_equal({}, lawyer.certifications)
  end

  # Active Status Tests
  test "should default to active true" do
    lawyer = Lawyer.new
    assert lawyer.active
  end

  test "should allow setting active status" do
    lawyer = Lawyer.create!(
      name: "Test Lawyer",
      email: "test2@example.com",
      phone: "+1234567890",
      license_number: "TEST-002",
      specialization: :customs,
      active: false
    )

    assert_not lawyer.active?
  end
end
