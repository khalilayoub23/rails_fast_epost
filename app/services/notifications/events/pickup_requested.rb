module Notifications
  module Events
    class PickupRequested < BaseEvent
      def initialize(task)
        super(task: task, message_type: message_type_for(:pickup_requested))
      end

      def deliver
        messenger = task&.messenger
        return if messenger.blank?

        if email_allowed?(messenger)
          deliver_email(TaskMailer.pickup_requested(task), message_type: message_type, notifiable: messenger)
        end

        if sms_allowed?(messenger)
          deliver_sms(
            recipient: messenger,
            message_type: message_type,
            body: builder.sms(:pickup_requested)
          )
        end

        log_notification(:pickup_requested, messenger)
      end
    end
  end
end
