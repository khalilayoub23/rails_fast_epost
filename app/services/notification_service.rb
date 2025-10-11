# Notification Service
# Handles all notification types: email, SMS (future), in-app (future)
class NotificationService
  class << self
    # Notify messenger about new task assignment
    def notify_task_assigned(task)
      return unless task.messenger.present?

      deliver_email(TaskMailer.task_assigned(task))
      log_notification(:task_assigned, task)
    end

    # Notify all parties about task status change
    def notify_status_changed(task, old_status)
      return unless should_notify_status_change?(task, old_status)

      # Notify customer
      deliver_email(TaskMailer.status_changed(task, old_status)) if task.customer.email.present?

      # Notify messenger if assigned
      deliver_email(TaskMailer.messenger_status_update(task, old_status)) if task.messenger.present?

      # Notify sender if set
      deliver_email(TaskMailer.sender_notification(task, old_status)) if task.sender&.email.present?

      log_notification(:status_changed, task, { old_status: old_status, new_status: task.status })
    end

    # Notify all parties about successful delivery
    def notify_delivery_complete(task)
      # Notify customer
      deliver_email(TaskMailer.delivery_complete(task)) if task.customer.email.present?

      # Notify sender if set
      deliver_email(TaskMailer.sender_delivery_complete(task)) if task.sender&.email.present?

      # Notify messenger
      deliver_email(TaskMailer.messenger_delivery_complete(task)) if task.messenger.present?

      log_notification(:delivery_complete, task)
    end

    # Notify messenger about pickup request
    def notify_pickup_requested(task)
      return unless task.messenger.present?

      deliver_email(TaskMailer.pickup_requested(task))
      log_notification(:pickup_requested, task)
    end

    # Notify about delivery failure
    def notify_delivery_failed(task)
      # Notify customer about failure
      deliver_email(TaskMailer.delivery_failed(task)) if task.customer.email.present?

      # Notify sender
      deliver_email(TaskMailer.sender_delivery_failed(task)) if task.sender&.email.present?

      # Alert admin
      deliver_email(TaskMailer.admin_delivery_alert(task))

      log_notification(:delivery_failed, task)
    end

    # Notify messenger about location update request
    def notify_location_update_requested(messenger)
      return unless messenger.present?

      deliver_email(TaskMailer.location_update_reminder(messenger))
      log_notification(:location_update_requested, messenger)
    end

    # Batch notify available messengers about pending tasks
    def notify_available_messengers_about_pending_tasks(messenger = nil, pending_tasks = nil)
      messenger ||= Messenger.available
      pending_tasks ||= Task.pending.where(messenger_id: nil).limit(10)

      return if pending_tasks.empty?

      messengers = messenger.is_a?(Messenger) ? [ messenger ] : messenger

      messengers.each do |m|
        deliver_email(TaskMailer.pending_tasks_alert(m, pending_tasks))
      end

      log_notification(:pending_tasks_alert, nil, count: pending_tasks.count)
    end

    private

    def deliver_email(mailer)
      # Use deliver_now in test environment for synchronous delivery
      # Use deliver_later in production for background job processing
      if Rails.env.test?
        mailer.deliver_now
      else
        mailer.deliver_later
      end
    end

    def should_notify_status_change?(task, old_status)
      # Only notify on significant status changes
      return false if old_status == task.status
      return false if old_status.nil?

      # Notify on these transitions
      significant_changes = %w[pending in_transit delivered failed returned]
      significant_changes.include?(task.status.to_s)
    end

    def log_notification(type, notifiable, extra_data = {})
      Rails.logger.info "[NotificationService] #{type} notification sent for #{notifiable.class.name}##{notifiable.id} #{extra_data}"
    rescue StandardError => e
      Rails.logger.error "[NotificationService] Error logging notification: #{e.message}"
    end
  end
end
