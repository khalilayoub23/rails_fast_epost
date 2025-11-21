module Notifications
  module Events
    class LocationUpdateRequested < BaseEvent
      def initialize(messenger:)
        @messenger = messenger
        super(task: nil, actor: messenger, message_type: message_type_for(:location_update_requested))
      end

      def deliver
        return if @messenger.blank?

        if email_allowed?(@messenger)
          deliver_email(TaskMailer.location_update_reminder(@messenger), message_type: message_type, notifiable: @messenger)
        end

        if sms_allowed?(@messenger)
          deliver_sms(
            recipient: @messenger,
            message_type: message_type,
            body: builder.sms(:location_update_requested, messenger: @messenger)
          )
        end

        log_notification(:location_update_requested, @messenger)
      end

      private

      def builder
        # No task context, but builder still needed for SMS copy.
        @builder ||= Notifications::MessageBuilder.new(nil)
      end
    end
  end
end
