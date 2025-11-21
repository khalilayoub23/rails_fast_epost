module Admin
  module Messengers
    class NotificationPreferencesController < ApplicationController
      before_action :require_admin_or_manager!
      before_action :authenticate_user!
      before_action :set_notification_preference, only: %i[ edit update destroy ]
      before_action :set_messenger

      def index
        @notification_preferences = @messenger.notification_preferences.order(:channel)
      end

      def new
        @notification_preference = @messenger.notification_preferences.build
      end

      def create
        @notification_preference = @messenger.notification_preferences.build(notification_preference_params)

        if @notification_preference.save
          redirect_to admin_messenger_notification_preferences_path(@messenger), notice: "Notification preference created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        if @notification_preference.update(notification_preference_params)
          redirect_to admin_messenger_notification_preferences_path(@messenger), notice: "Notification preference updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @notification_preference.destroy
        redirect_to admin_messenger_notification_preferences_path(@messenger), notice: "Notification preference removed."
      end

      private

      def set_notification_preference
        @notification_preference = NotificationPreference.find(params[:id])
      end

      def set_messenger
        @messenger = if params[:messenger_id]
          Messenger.find(params[:messenger_id])
        else
          @notification_preference&.notifiable
        end
      end

      def notification_preference_params
        params.require(:notification_preference).permit(:channel, :enabled, :quiet_hours_start, :quiet_hours_end)
      end

      def require_admin_or_manager!
        unless current_user&.admin? || current_user&.manager?
          redirect_to root_path, alert: "Access denied"
        end
      end
    end
  end
end
