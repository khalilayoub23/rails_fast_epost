require "application_system_test_case"

class ParcelTrackingTest < ApplicationSystemTestCase
  def setup
    @task = tasks(:one)
  end

  test "visitor can view tracking details for existing parcel" do
    visit pages_track_parcel_path

    fill_in I18n.t("track.tracking_number"), with: @task.barcode
    click_button I18n.t("track.track_button")

    assert_text I18n.t("track.tracking_details")
    assert_text @task.barcode
    assert_text @task.start
    assert_text @task.target
    assert_text "Package Picked Up"
    assert_text "Out for Delivery"
    assert_text "Order Created"
    assert_text "Delivered"

    timeline_html = page.body
    assert_match(/Order Created.*Package Picked Up.*Out for Delivery.*Delivered/m, timeline_html)
  end

  test "visitor sees not found message for unknown tracking number" do
    visit pages_track_parcel_path

    fill_in I18n.t("track.tracking_number"), with: "UNKNOWN123"
    click_button I18n.t("track.track_button")

    assert_text "Tracking number not found. Please check and try again."
  end

  test "visitor sees failure note when delivery attempts failed" do
    @task.tracking_events.destroy_all
    now = Time.current
    TrackingEvent.create!(
      task: @task,
      event_type: "failed",
      title: "Delivery Attempt Failed",
      status: "failed",
      description: "Recipient not available",
      occurred_at: now - 2.hours,
      metadata: { attempt_number: 1 }
    )
    TrackingEvent.create!(
      task: @task,
      event_type: "failed",
      title: "Delivery Attempt Failed",
      status: "failed",
      description: "Left notice at door",
      occurred_at: now - 1.hour,
      metadata: { attempt_number: 2 }
    )

    @task.update!(failed_attempts: 2,
                  last_failure_note: "Recipient not available",
                  status: :failed,
                  awaiting_customer_response: true,
                  stored_until: 2.days.from_now)

    visit pages_track_parcel_path

    fill_in I18n.t("track.tracking_number"), with: @task.barcode
    click_button I18n.t("track.track_button")

    assert_text "Delivery issues reported"
    assert_text "Failed attempts: 2 of #{Task::MAX_FAILED_ATTEMPTS}"
    assert_text "Carrier note: Recipient not available"
    assert_text "Action needed:"  # ensures storage message visible
    assert_text "Attempt 1"
    assert_text "Attempt 2"
  end
end
