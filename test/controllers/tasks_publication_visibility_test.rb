require "test_helper"

class TasksPublicationVisibilityTest < ActionDispatch::IntegrationTest
  setup do
    @customer = customers(:one)
    @carrier = carriers(:one)
    @creator = users(:sender)
    @manager = users(:manager)
  end

  test "creator sees own draft but others only see published" do
    draft = Task.create!(
      customer: @customer,
      carrier: @carrier,
      package_type: "Draft Parcel",
      start: "A",
      target: "B",
      delivery_time: 1.day.from_now,
      created_by: @creator,
      published: false
    )

    published = Task.create!(
      customer: @customer,
      carrier: @carrier,
      package_type: "Published Parcel",
      start: "P",
      target: "Q",
      delivery_time: 1.day.from_now,
      created_by: @creator,
      published: true
    )

    sign_in @creator
    get tasks_path
    assert_response :success
    assert_includes response.body, "Draft Parcel"
    assert_includes response.body, "Published Parcel"

    sign_out @creator
    sign_in users(:viewer)
    get tasks_path
    assert_response :success
    refute_includes response.body, "Draft Parcel"
    assert_includes response.body, "Published Parcel"

    sign_out users(:viewer)
    sign_in @manager
    get tasks_path
    assert_response :success
    assert_includes response.body, "Draft Parcel"
    assert_includes response.body, "Published Parcel"
  end
end
