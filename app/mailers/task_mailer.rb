# Task Mailer - Handles all task-related email notifications
class TaskMailer < ApplicationMailer
  default from: 'notifications@fastepost.com'

  # Notify messenger about new task assignment
  def task_assigned(task)
    @task = task
    @messenger = task.messenger
    @customer = task.customer
    
    mail(
      to: @messenger.email,
      subject: "New Task Assigned: #{@task.barcode}"
    )
  end

  # Notify customer and messenger about status change
  def status_changed(task, old_status)
    @task = task
    @old_status = old_status
    @new_status = task.status
    @customer = task.customer
    
    mail(
      to: @customer.email,
      subject: "Shipment Update: #{@task.barcode} is now #{@new_status.titleize}"
    )
  end

  # Notify messenger about status update
  def messenger_status_update(task, old_status)
    @task = task
    @old_status = old_status
    @new_status = task.status
    @messenger = task.messenger
    
    mail(
      to: @messenger.email,
      subject: "Task Status Updated: #{@task.barcode}"
    )
  end

  # Notify sender about status change
  def sender_notification(task, old_status)
    @task = task
    @old_status = old_status
    @new_status = task.status
    @sender = task.sender
    
    mail(
      to: @sender.email,
      subject: "Shipment Update for #{@task.barcode}"
    )
  end

  # Notify customer about successful delivery
  def delivery_complete(task)
    @task = task
    @customer = task.customer
    @messenger = task.messenger
    
    mail(
      to: @customer.email,
      subject: "Delivered: #{@task.barcode}"
    )
  end

  # Notify sender about successful delivery
  def sender_delivery_complete(task)
    @task = task
    @sender = task.sender
    @customer = task.customer
    
    mail(
      to: @sender.email,
      subject: "Delivery Confirmation: #{@task.barcode}"
    )
  end

  # Notify messenger about completed delivery
  def messenger_delivery_complete(task)
    @task = task
    @messenger = task.messenger
    
    mail(
      to: @messenger.email,
      subject: "Delivery Completed: #{@task.barcode}"
    )
  end

  # Notify messenger about pickup request
  def pickup_requested(task)
    @task = task
    @messenger = task.messenger
    @sender = task.sender
    
    mail(
      to: @messenger.email,
      subject: "Pickup Request: #{@task.barcode}"
    )
  end

  # Notify customer about delivery failure
  def delivery_failed(task)
    @task = task
    @customer = task.customer
    @failure_reason = task.failure_code_text
    
    mail(
      to: @customer.email,
      subject: "Delivery Failed: #{@task.barcode}"
    )
  end

  # Notify sender about delivery failure
  def sender_delivery_failed(task)
    @task = task
    @sender = task.sender
    @failure_reason = task.failure_code_text
    
    mail(
      to: @sender.email,
      subject: "Delivery Failed: #{@task.barcode}"
    )
  end

  # Alert admin about delivery failure
  def admin_delivery_alert(task)
    @task = task
    @customer = task.customer
    @failure_reason = task.failure_code_text
    
    mail(
      to: 'admin@fastepost.com',
      subject: "ALERT: Delivery Failed - #{@task.barcode}"
    )
  end

  # Remind messenger to update location
  def location_update_reminder(messenger)
    @messenger = messenger
    
    mail(
      to: @messenger.email,
      subject: "Please Update Your Location"
    )
  end

  # Alert available messengers about pending tasks
  def pending_tasks_alert(messenger, pending_tasks)
    @messenger = messenger
    @pending_tasks = pending_tasks
    
    mail(
      to: @messenger.email,
      subject: "#{@pending_tasks.count} Tasks Available for Pickup"
    )
  end
end
