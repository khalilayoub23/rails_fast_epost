module Notifications
  module Events
    class BaseEvent < Notifications::Notifier
      attr_reader :message_type

      def initialize(task: nil, actor: nil, message_type:)
        super(task: task, actor: actor)
        @message_type = message_type
      end

      def deliver
        raise NotImplementedError, "Subclasses must implement #deliver"
      end

      private

      def builder
        @builder ||= Notifications::MessageBuilder.new(task)
      end

      def log_notification(type, notifiable, extra_data = {})
        identifier = if notifiable.nil?
          "None"
        elsif notifiable.respond_to?(:id)
          "#{notifiable.class.name}##{notifiable.id}"
        else
          notifiable.class.name
        end

        Rails.logger.info "[NotificationService] #{type} notification sent for #{identifier} #{extra_data}"
      rescue StandardError => e
        Rails.logger.error "[NotificationService] Error logging notification: #{e.message}"
      end

      def message_type_for(key)
        NotificationService::MESSAGE_TYPES.fetch(key)
      end
    end
  end
end
