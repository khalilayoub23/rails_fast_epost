module Notifications
  module Events
    class DeliveryFailed < BaseEvent
      def initialize(task)
        super(task: task, message_type: message_type_for(:delivery_failed))
      end

      def deliver
        notify_customer
        notify_sender
        notify_admin
        log_notification(:delivery_failed, task)
      end

      private

      def notify_customer
        customer = task.customer
        return if customer.blank?

        if email_allowed?(customer)
          deliver_email(TaskMailer.delivery_failed(task), message_type: message_type, notifiable: customer)
        end

        if sms_allowed?(customer)
          deliver_sms(
            recipient: customer,
            message_type: message_type,
            body: builder.sms(:delivery_failed)
          )
        end
      end

      def notify_sender
        sender = task.sender
        return if sender.blank?

        if email_allowed?(sender)
          deliver_email(TaskMailer.sender_delivery_failed(task), message_type: message_type, notifiable: sender)
        end
      end

      def notify_admin
        deliver_email(TaskMailer.admin_delivery_alert(task), message_type: message_type, notifiable: nil)
      end
    end
  end
end
