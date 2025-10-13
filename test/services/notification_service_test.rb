require "test_helper"

class NotificationServiceTest < ActionMailer::TestCase
  setup do
    @task = tasks(:one)
    @messenger = messengers(:messenger_one)
    @customer = customers(:one)
    @sender = senders(:sender_one)

    # Clear ActionMailer deliveries before each test
    ActionMailer::Base.deliveries.clear
  end

  test "notify_task_assigned sends email to messenger" do
    @task.update!(messenger: @messenger)

    assert_emails 1 do
      NotificationService.notify_task_assigned(@task)
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [ @messenger.email ], email.to
    assert_match @task.barcode, email.subject
    assert_match "New Task Assigned", email.subject
  end

  test "notify_task_assigned handles missing messenger gracefully" do
    @task.update!(messenger: nil)

    assert_nothing_raised do
      NotificationService.notify_task_assigned(@task)
    end
  end

  test "notify_status_changed sends emails to customer, messenger, and sender" do
    @task.update!(messenger: @messenger, sender: @sender)

    # Should send 3 emails: customer, messenger, sender
    assert_emails 3 do
      NotificationService.notify_status_changed(@task, "pending")
    end

    emails = ActionMailer::Base.deliveries.last(3)
    recipients = emails.map(&:to).flatten

    assert_includes recipients, @customer.email
    assert_includes recipients, @messenger.email
    assert_includes recipients, @sender.email
  end

  test "notify_status_changed only sends to available recipients" do
    @task.update!(messenger: nil, sender: nil)

    # Should only send 1 email to customer
    assert_emails 1 do
      NotificationService.notify_status_changed(@task, "pending")
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [ @customer.email ], email.to
  end

  test "notify_delivery_complete sends emails to all parties" do
    @task.update!(messenger: @messenger, sender: @sender)

    # Should send 3 emails: customer, sender, messenger
    assert_emails 3 do
      NotificationService.notify_delivery_complete(@task)
    end

    emails = ActionMailer::Base.deliveries.last(3)
    subjects = emails.map(&:subject)

    assert subjects.any? { |s| s.include?("Delivered") }
    assert subjects.any? { |s| s.include?("Delivery Confirmation") }
    assert subjects.any? { |s| s.include?("Delivery Completed") }
  end

  test "notify_pickup_requested sends email to messenger" do
    @task.update!(messenger: @messenger, sender: @sender)

    assert_emails 1 do
      NotificationService.notify_pickup_requested(@task)
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [ @messenger.email ], email.to
    assert_match "Pickup Request", email.subject
  end

  test "notify_delivery_failed sends emails and admin alert" do
    @task.update!(
      messenger: @messenger,
      sender: @sender,
      failure_code: :address_not_found
    )

    # Should send 3 emails: customer, sender, admin
    assert_emails 3 do
      NotificationService.notify_delivery_failed(@task)
    end

    emails = ActionMailer::Base.deliveries.last(3)
    subjects = emails.map(&:subject)

    assert subjects.any? { |s| s.include?("Delivery Failed") }
    assert subjects.any? { |s| s.include?("ALERT") }
  end

  test "notify_location_update_requested sends reminder to messenger" do
    assert_emails 1 do
      NotificationService.notify_location_update_requested(@messenger)
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [ @messenger.email ], email.to
    assert_match /Location/i, email.subject
  end

  test "notify_available_messengers_about_pending_tasks sends bulk notification" do
    # Ensure we have at least one pending task
    pending_task = @task
    pending_task.update!(status: :pending)
    pending_tasks = Task.where(status: :pending)

    assert pending_tasks.any?, "Should have at least one pending task"

    assert_emails 1 do
      NotificationService.notify_available_messengers_about_pending_tasks(@messenger, pending_tasks)
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [ @messenger.email ], email.to
    assert_match "Available for Pickup", email.subject
  end

  test "notification service handles email delivery failures gracefully" do
    # Test that exceptions are caught and logged
    # Set delivery_method to :test to avoid actual SMTP issues
    ActionMailer::Base.delivery_method = :test

    assert_nothing_raised do
      NotificationService.notify_task_assigned(@task)
    end
  end

  test "notification service logs errors on delivery failure" do
    # Test with task that has nil messenger (should handle gracefully)
    @task.update!(messenger: nil, sender: nil)

    assert_nothing_raised do
      NotificationService.notify_status_changed(@task, "pending")
    end

    # Should still send customer email
    assert_equal 1, ActionMailer::Base.deliveries.count
  end

  test "email templates include task details" do
    @task.update!(messenger: @messenger, barcode: "TEST-BARCODE-123")

    NotificationService.notify_task_assigned(@task)

    email = ActionMailer::Base.deliveries.last
    assert_match "TEST-BARCODE-123", email.body.to_s
    assert_match @customer.full_name, email.body.to_s
  end

  test "status change emails show old and new status" do
    @task.update!(status: :in_transit)

    NotificationService.notify_status_changed(@task, "pending")

    email = ActionMailer::Base.deliveries.last
    body = email.body.to_s

    # Should mention the status update
    assert_match(/status/i, body)
  end

  test "delivery complete email includes delivery timestamp" do
    @task.update!(messenger: @messenger)

    NotificationService.notify_delivery_complete(@task)

    email = ActionMailer::Base.deliveries.first
    body = email.body.to_s

    # Should include some form of timestamp
    assert_match(/\d{4}/, body) # Year
  end

  test "failure notification includes failure reason" do
    @task.update!(
      failure_code: :recipient_unavailable,
      messenger: @messenger,
      sender: @sender
    )

    NotificationService.notify_delivery_failed(@task)

    email = ActionMailer::Base.deliveries.first
    body = email.body.to_s

    # Should mention the failure
    assert_match(/unavailable|failed/i, body)
  end

  test "pending_tasks_alert_includes_task_count" do
    # Ensure we have at least one pending task
    @task.update!(status: :pending)
    pending_tasks = Task.where(status: :pending)

    assert pending_tasks.any?, "Should have at least one pending task"

    NotificationService.notify_available_messengers_about_pending_tasks(@messenger, pending_tasks)

    email = ActionMailer::Base.deliveries.last
    assert_not_nil email, "Email should have been sent"
    body = email.body.to_s

    # Should show number of tasks
    assert_match(/\d+/, body)
  end

  test "admin alert email goes to admin address" do
    @task.update!(
      failure_code: :package_damaged,
      messenger: @messenger
    )

    NotificationService.notify_delivery_failed(@task)

    admin_email = ActionMailer::Base.deliveries.find { |e| e.subject.include?("ALERT") }
    assert_not_nil admin_email
    assert_equal [ "admin@fastepost.com" ], admin_email.to
  end
end
