module Notifications
  module Events
    class DeliveryComplete < BaseEvent
      def initialize(task)
        super(task: task, message_type: message_type_for(:delivery_complete))
      end

      def deliver
        notify_customer
        notify_sender
        notify_messenger
        log_notification(:delivery_complete, task)
      end

      private

      def notify_customer
        customer = task.customer
        return if customer.blank?

        if email_allowed?(customer)
          deliver_email(TaskMailer.delivery_complete(task), message_type: message_type, notifiable: customer)
        end

        if sms_allowed?(customer)
          deliver_sms(
            recipient: customer,
            message_type: message_type,
            body: builder.sms(:delivery_complete)
          )
        end
      end

      def notify_sender
        sender = task.sender
        return if sender.blank?

        if email_allowed?(sender)
          deliver_email(TaskMailer.sender_delivery_complete(task), message_type: message_type, notifiable: sender)
        end
      end

      def notify_messenger
        messenger = task.messenger
        return if messenger.blank?

        if email_allowed?(messenger)
          deliver_email(TaskMailer.messenger_delivery_complete(task), message_type: message_type, notifiable: messenger)
        end
      end
    end
  end
end
