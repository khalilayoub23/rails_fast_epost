require "test_helper"

class Api::V1::Carriers::TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:operations_manager)
    sign_in @user
    @task = tasks(:one)
  end

  test "returns tasks for carrier" do
    get api_v1_carriers_tasks_path(format: :json)
    assert_response :success
    payload = JSON.parse(response.body)
    assert payload.is_a?(Array)
    assert payload.any? { |row| row["barcode"] == @task.barcode }
  end

  test "updates task status" do
    patch api_v1_carriers_task_path(@task, format: :json), params: { task: { status: "delivered" } }
    assert_response :success
    @task.reload
    assert @task.delivered?
  end
end
