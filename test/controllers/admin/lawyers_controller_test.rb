require "test_helper"

class Admin::LawyersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lawyer = lawyers(:lawyer_one)
    @user = users(:admin)
    sign_in @user # Assuming you have authentication
  end

  # Index Tests
  test "should get index" do
    get admin_lawyers_url
    assert_response :success
    assert_not_nil assigns(:lawyers)
  end

  test "should search lawyers by name" do
    get admin_lawyers_url, params: { search: @lawyer.name }
    assert_response :success
    assert_includes assigns(:lawyers), @lawyer
  end

  test "should filter lawyers by status" do
    get admin_lawyers_url, params: { status: "active" }
    assert_response :success
    assert assigns(:lawyers).all?(&:active?)
  end

  test "should filter lawyers by specialization" do
    get admin_lawyers_url, params: { specialization: "customs" }
    assert_response :success
    assert assigns(:lawyers).all? { |l| l.specialization == "customs" }
  end

  # Show Tests
  test "should show lawyer" do
    get admin_lawyer_url(@lawyer)
    assert_response :success
    assert_equal @lawyer, assigns(:lawyer)
  end

  # New Tests
  test "should get new" do
    get new_admin_lawyer_url
    assert_response :success
    assert_not_nil assigns(:lawyer)
    assert assigns(:lawyer).new_record?
  end

  # Create Tests
  test "should create lawyer" do
    assert_difference("Lawyer.count") do
      post admin_lawyers_url, params: {
        lawyer: {
          name: "New Lawyer",
          email: "new.lawyer@example.com",
          phone: "+1234567890",
          license_number: "NEW-001",
          specialization: "customs",
          bar_association: "Test Bar",
          notes: "Test notes",
          active: true
        }
      }
    end

    assert_redirected_to admin_lawyer_url(Lawyer.last)
    assert_equal "Lawyer successfully created.", flash[:notice]
  end

  test "should not create lawyer with invalid data" do
    assert_no_difference("Lawyer.count") do
      post admin_lawyers_url, params: {
        lawyer: {
          name: "",
          email: "invalid",
          phone: "",
          license_number: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create lawyer with duplicate email" do
    assert_no_difference("Lawyer.count") do
      post admin_lawyers_url, params: {
        lawyer: {
          name: "Duplicate Email",
          email: @lawyer.email,
          phone: "+1234567890",
          license_number: "DUP-001",
          specialization: "customs"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit Tests
  test "should get edit" do
    get edit_admin_lawyer_url(@lawyer)
    assert_response :success
    assert_equal @lawyer, assigns(:lawyer)
  end

  # Update Tests
  test "should update lawyer" do
    patch admin_lawyer_url(@lawyer), params: {
      lawyer: {
        name: "Updated Name",
        notes: "Updated notes"
      }
    }

    assert_redirected_to admin_lawyer_url(@lawyer)
    assert_equal "Lawyer successfully updated.", flash[:notice]

    @lawyer.reload
    assert_equal "Updated Name", @lawyer.name
    assert_equal "Updated notes", @lawyer.notes
  end

  test "should not update lawyer with invalid data" do
    original_name = @lawyer.name

    patch admin_lawyer_url(@lawyer), params: {
      lawyer: {
        name: "",
        email: "invalid"
      }
    }

    assert_response :unprocessable_entity

    @lawyer.reload
    assert_equal original_name, @lawyer.name
  end

  # Destroy Tests
  test "should destroy lawyer" do
    assert_difference("Lawyer.count", -1) do
      delete admin_lawyer_url(@lawyer)
    end

    assert_redirected_to admin_lawyers_url
    assert_equal "Lawyer successfully deleted.", flash[:notice]
  end

  # Activate Tests
  test "should activate lawyer" do
    inactive_lawyer = lawyers(:lawyer_five)
    assert_not inactive_lawyer.active?

    patch activate_admin_lawyer_url(inactive_lawyer)

    assert_redirected_to admin_lawyer_url(inactive_lawyer)
    assert_equal "Lawyer activated successfully.", flash[:notice]

    inactive_lawyer.reload
    assert inactive_lawyer.active?
  end

  # Deactivate Tests
  test "should deactivate lawyer" do
    assert @lawyer.active?

    patch deactivate_admin_lawyer_url(@lawyer)

    assert_redirected_to admin_lawyer_url(@lawyer)
    assert_equal "Lawyer deactivated successfully.", flash[:notice]

    @lawyer.reload
    assert_not @lawyer.active?
  end

  # Authorization Tests (if applicable)
  # Uncomment and adjust these tests if you have authorization in place

  # test "should not allow access without authentication" do
  #   sign_out @user
  #   get admin_lawyers_url
  #   assert_redirected_to login_url
  # end

  # test "should not allow non-admin access" do
  #   viewer = users(:viewer)
  #   sign_in viewer
  #   get admin_lawyers_url
  #   assert_redirected_to root_url
  #   assert_equal "You are not authorized to access this page.", flash[:alert]
  # end
end
