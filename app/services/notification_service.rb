# Notification Service
# Handles all notification types: email, SMS, in-app (future)
class NotificationService
  MESSAGE_TYPES = {
    task_assigned: :task_assigned,
    status_changed: :status_changed,
    delivery_complete: :delivery_complete,
    pickup_requested: :pickup_requested,
    delivery_failed: :delivery_failed,
    location_update_requested: :location_update_requested,
    pending_tasks_alert: :pending_tasks_alert
  }.freeze

  class << self
    def notify_task_assigned(task)
      Notifications::Events::TaskAssigned.new(task).deliver
    end

    def notify_status_changed(task, old_status)
      Notifications::Events::StatusChanged.new(task, old_status).deliver
    end

    def notify_delivery_complete(task)
      Notifications::Events::DeliveryComplete.new(task).deliver
    end

    def notify_pickup_requested(task)
      Notifications::Events::PickupRequested.new(task).deliver
    end

    def notify_delivery_failed(task)
      Notifications::Events::DeliveryFailed.new(task).deliver
    end

    def notify_location_update_requested(messenger)
      Notifications::Events::LocationUpdateRequested.new(messenger: messenger).deliver
    end

    def notify_available_messengers_about_pending_tasks(messenger = nil, pending_tasks = nil)
      Notifications::Events::PendingTasksAlert.new(messenger: messenger, pending_tasks: pending_tasks).deliver
    end
  end
end
