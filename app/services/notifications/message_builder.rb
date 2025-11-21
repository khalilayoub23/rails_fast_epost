module Notifications
  class MessageBuilder
    def initialize(task)
      @task = task
    end

    def sms(event, extras = {})
      task = extras.delete(:task) || @task
      barcode = task&.barcode || "task"

      case event
      when :task_assigned
        start_location = task&.start || "soon"
        "FastEpost: Task #{barcode} assigned. Pickup #{start_location}."
      when :status_changed
        status_text = task&.status ? task.status.humanize : "updated"
        "FastEpost: Task #{barcode} is now #{status_text}."
      when :delivery_complete
        "FastEpost: Task #{barcode} delivered successfully."
      when :pickup_requested
        "FastEpost: Pickup requested for task #{barcode}."
      when :delivery_failed
        reason = task&.failure_code_text || "issue"
        "FastEpost: Task #{barcode} failed (#{reason})."
      when :location_update_requested
        messenger = extras[:messenger]
        "FastEpost: Hi #{messenger&.name || 'messenger'}, please update your location."
      when :pending_tasks_alert
        count = extras[:count] || 0
        "FastEpost: #{count} pending tasks need pickup. Claim them in the dashboard."
      else
        "FastEpost update available."
      end
    end
  end
end
