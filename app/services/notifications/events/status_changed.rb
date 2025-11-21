module Notifications
  module Events
    class StatusChanged < BaseEvent
      def initialize(task, old_status)
        @old_status = old_status
        super(task: task, message_type: message_type_for(:status_changed))
      end

      def deliver
        return unless significant_change?

        notify_customer
        notify_messenger
        notify_sender
        log_notification(:status_changed, task, { old_status: @old_status, new_status: task.status })
      end

      private

      def notify_customer
        customer = task.customer
        return if customer.blank?

        if email_allowed?(customer)
          deliver_email(TaskMailer.status_changed(task, @old_status), message_type: message_type, notifiable: customer)
        end

        if sms_allowed?(customer)
          deliver_sms(
            recipient: customer,
            message_type: message_type,
            body: builder.sms(:status_changed)
          )
        end
      end

      def notify_messenger
        messenger = task.messenger
        return if messenger.blank?

        if email_allowed?(messenger)
          deliver_email(TaskMailer.messenger_status_update(task, @old_status), message_type: message_type, notifiable: messenger)
        end

        if sms_allowed?(messenger)
          deliver_sms(
            recipient: messenger,
            message_type: message_type,
            body: builder.sms(:status_changed)
          )
        end
      end

      def notify_sender
        sender = task.sender
        return if sender.blank?

        if email_allowed?(sender)
          deliver_email(TaskMailer.sender_notification(task, @old_status), message_type: message_type, notifiable: sender)
        end
      end

      def significant_change?
        return false if @old_status.nil?
        return false if @old_status == task.status

        %w[pending in_transit delivered failed returned].include?(task.status.to_s)
      end
    end
  end
end
