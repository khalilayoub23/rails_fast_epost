module Notifications
  module Events
    class TaskAssigned < BaseEvent
      def initialize(task)
        super(task: task, message_type: message_type_for(:task_assigned))
      end

      def deliver
        messenger = task&.messenger
        return if messenger.blank?

        if email_allowed?(messenger)
          deliver_email(TaskMailer.task_assigned(task), message_type: message_type, notifiable: messenger)
        end

        if sms_allowed?(messenger)
          deliver_sms(
            recipient: messenger,
            message_type: message_type,
            body: builder.sms(:task_assigned)
          )
        end

        log_notification(:task_assigned, messenger)
      end
    end
  end
end
