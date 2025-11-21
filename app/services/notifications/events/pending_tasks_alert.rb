module Notifications
  module Events
    class PendingTasksAlert < BaseEvent
      def initialize(messenger:, pending_tasks:)
        @messenger_param = messenger
        @pending_tasks_param = pending_tasks
        super(task: nil, message_type: message_type_for(:pending_tasks_alert))
      end

      def deliver
        tasks = pending_tasks
        return if tasks.empty?

        recipients = messenger_list
        return if recipients.empty?

        emails = recipients.select { |m| email_allowed?(m) }
        sms_targets = recipients.select { |m| sms_allowed?(m) }

        emails.each do |m|
          deliver_email(TaskMailer.pending_tasks_alert(m, tasks), message_type: message_type, notifiable: m)
        end

        sms_targets.each do |m|
          deliver_sms(
            recipient: m,
            message_type: message_type,
            body: builder.sms(:pending_tasks_alert, count: tasks.count)
          )
        end

        log_notification(:pending_tasks_alert, nil, count: tasks.count)
      end

      private

      def pending_tasks
        @pending_tasks ||= begin
          tasks = @pending_tasks_param
          tasks = Task.pending.where(messenger_id: nil).limit(10) if tasks.blank?
          tasks.respond_to?(:limit) ? tasks : Array(tasks)
        end
      end

      def messenger_list
        @messenger_list ||= begin
          messenger = @messenger_param
          messenger ||= Messenger.available
          messenger.is_a?(Messenger) ? [ messenger ] : Array(messenger)
        end
      end

      def builder
        # Pending alerts aren't tied to one task, but we still reuse the copy helper.
        @builder ||= Notifications::MessageBuilder.new(nil)
      end
    end
  end
end
