require "application_system_test_case"

class DashboardFlowsTest < ApplicationSystemTestCase
  test "admin dashboard shows KPIs and key sections" do
    login_as users(:admin)
    visit dashboard_path

    assert_selector "#dashboard_kpis .group", minimum: 4
    assert_selector "h3", text: I18n.t("dashboard.recent_payments", default: "Payments")
    assert_no_selector "form[action='#{dashboard_path}'][method='get'] select[name='payment_filter[status]']"
    assert_selector "h3", text: I18n.t("dashboard.recent_tasks", default: "Tasks")
    assert_selector "h3", text: I18n.t("deliveries.index.title", default: "Deliveries")
  end

  test "support agent dashboard shows operational filters" do
    login_as users(:support_agent_user)
    visit dashboard_path

    assert_selector "#dashboard_kpis .group", minimum: 4
    assert_no_selector "form[action='#{dashboard_path}'][method='get'] select[name='task_filter[status]']"
    assert_no_selector "form[action='#{dashboard_path}'][method='get'] select[name='delivery_filter[status]']"
    assert_selector "h3", text: I18n.t("dashboard.recent_tasks", default: "Tasks")
  end

  test "carrier staff dashboard shows payouts and tasks" do
    login_as users(:carrier_staff_user)
    visit dashboard_path

    assert_selector "#dashboard_kpis .group", minimum: 4
    assert_selector "h3", text: I18n.t("dashboard.recent_payouts", default: "Payouts")
    assert_selector "table", text: I18n.t("dashboard.status", default: "Status")
  end

  test "sender dashboard shows personal payments" do
    login_as users(:sender)
    visit dashboard_path

    assert_selector "#dashboard_kpis .group", minimum: 4
    assert_selector "h3", text: I18n.t("dashboard.recent_payments", default: "Recent payments")
    assert_selector "table", text: I18n.t("dashboard.status", default: "Status")
  end

  test "admin can reach task and carrier creation from dashboard" do
    login_as users(:admin)
    visit dashboard_path

    click_link I18n.t("sidebar.tasks", default: "Tasks")
    assert_current_path tasks_path
    assert_selector "a", text: I18n.t("tasks.new", default: "New")
    click_link I18n.t("tasks.new", default: "New")
    assert_selector "form[action='#{tasks_path}']"

    visit dashboard_path
    click_link I18n.t("sidebar.carriers", default: "Carriers")
    assert_current_path carriers_path
    assert_selector "a", text: "New Carrier"
    click_link "New Carrier"
    assert_selector "form[action='#{carriers_path}']"
  end

  test "dashboard widget view-all links navigate correctly" do
    login_as users(:admin)
    visit dashboard_path

    within "[data-widget-id='recent_payments']" do
      click_link I18n.t("dashboard.view_all", default: "View all")
    end
    assert_current_path payments_path

    visit dashboard_path
    within "[data-widget-id='recent_tasks']" do
      click_link I18n.t("dashboard.view_all", default: "View all")
    end
    assert_current_path tasks_path

    visit dashboard_path
    within "[data-widget-id='deliveries']" do
      click_link I18n.t("dashboard.view_all", default: "View all")
    end
    assert_current_path deliveries_path

    login_as users(:carrier_staff_user)
    visit dashboard_path
    within "[data-widget-id='payouts']" do
      click_link I18n.t("dashboard.view_all", default: "View all")
    end
    assert_current_path control_panel_carriers_payouts_path
  end
end
