require "test_helper"

class TaskMailerTest < ActionMailer::TestCase
  setup do
    @task = tasks(:one)
    @messenger = messengers(:messenger_one)
    @customer = customers(:one)
    @sender = senders(:sender_one)

    @task.update!(
      messenger: @messenger,
      customer: @customer,
      sender: @sender
    )
  end

  test "task_assigned email" do
    email = TaskMailer.task_assigned(@task)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "notifications@fastepost.com" ], email.from
    assert_equal [ @messenger.email ], email.to
    assert_match "New Task Assigned", email.subject
    assert_match @task.barcode, email.subject
    assert_match @messenger.name, email.body.encoded
    assert_match @customer.full_name, email.body.encoded
  end

  test "status_changed email to customer" do
    email = TaskMailer.status_changed(@task, "pending")

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @customer.email ], email.to
    assert_match "Shipment Update", email.subject
    assert_match @task.barcode, email.body.encoded
  end

  test "messenger_status_update email" do
    email = TaskMailer.messenger_status_update(@task, "pending")

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @messenger.email ], email.to
    assert_match "Task Status Updated", email.subject
    assert_match @task.barcode, email.body.encoded
  end

  test "sender_notification email" do
    email = TaskMailer.sender_notification(@task, "pending")

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @sender.email ], email.to
    assert_match "Shipment Update", email.subject
    assert_match @task.barcode, email.body.encoded
  end

  test "delivery_complete email to customer" do
    email = TaskMailer.delivery_complete(@task)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @customer.email ], email.to
    assert_match "Delivered", email.subject
    assert_match @task.barcode, email.body.encoded
    assert_match @messenger.name, email.body.encoded
  end

  test "sender_delivery_complete email" do
    email = TaskMailer.sender_delivery_complete(@task)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @sender.email ], email.to
    assert_match "Delivery Confirmation", email.subject
    assert_match @task.barcode, email.body.encoded
  end

  test "messenger_delivery_complete email" do
    email = TaskMailer.messenger_delivery_complete(@task)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @messenger.email ], email.to
    assert_match /Completed/i, email.subject
    assert_match @task.barcode, email.body.encoded
  end

  test "pickup_requested email" do
    email = TaskMailer.pickup_requested(@task)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @messenger.email ], email.to
    assert_match "Pickup Request", email.subject
    assert_match @task.barcode, email.body.encoded
    assert_match @sender.name, email.body.encoded
  end

  test "delivery_failed email to customer" do
    @task.update!(failure_code: :address_not_found)
    email = TaskMailer.delivery_failed(@task)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @customer.email ], email.to
    assert_match "Delivery Failed", email.subject
    assert_match @task.barcode, email.body.encoded
  end

  test "sender_delivery_failed email" do
    @task.update!(failure_code: :recipient_unavailable)
    email = TaskMailer.sender_delivery_failed(@task)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @sender.email ], email.to
    assert_match "Delivery Failed", email.subject
    assert_match @task.barcode, email.body.encoded
  end

  test "admin_delivery_alert email" do
    @task.update!(failure_code: :package_damaged)
    email = TaskMailer.admin_delivery_alert(@task)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "admin@fastepost.com" ], email.to
    assert_match "ALERT", email.subject
    assert_match "Delivery Failed", email.subject
    assert_match @task.barcode, email.body.encoded
    assert_match @customer.full_name, email.body.encoded
    assert_match @customer.email, email.body.encoded
  end

  test "location_update_reminder email" do
    email = TaskMailer.location_update_reminder(@messenger)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @messenger.email ], email.to
    assert_match /Location/i, email.subject
    assert_match @messenger.name, email.body.encoded
  end

  test "pending_tasks_alert email" do
    pending_tasks = Task.where(status: :pending).limit(3)
    email = TaskMailer.pending_tasks_alert(@messenger, pending_tasks)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @messenger.email ], email.to
    assert_match "Available for Pickup", email.subject
    assert_match @messenger.name, email.body.encoded
    assert_match pending_tasks.count.to_s, email.body.encoded
  end

  test "emails have proper HTML structure" do
    email = TaskMailer.task_assigned(@task)

    assert_match /<html>/i, email.body.encoded
    assert_match /<\/html>/i, email.body.encoded
    assert_match /<body>/i, email.body.encoded
  end

  test "emails include tracking links" do
    email = TaskMailer.status_changed(@task, "pending")

    assert_match /tracking/i, email.body.encoded
  end

  test "urgent tasks are highlighted in emails" do
    @task.update!(priority: "urgent")
    email = TaskMailer.pickup_requested(@task)

    assert_match /URGENT/i, email.body.encoded
  end

  test "express tasks render express banner" do
    @task.update!(priority: "express")
    email = TaskMailer.pickup_requested(@task)

    assert_match /EXPRESS/i, email.body.encoded
  end

  test "failure emails include failure reason text" do
    @task.update!(failure_code: :refused_delivery)
    email = TaskMailer.delivery_failed(@task)

    # Should include the failure reason
    assert_match @task.failure_code_text, email.body.encoded
  end
end
