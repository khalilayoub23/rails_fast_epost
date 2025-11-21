class NotificationPreferencesControllerBase < ApplicationController
  class_attribute :notifiable_model, instance_writer: false

  before_action :authenticate_user!
  before_action :set_notification_preference, only: %i[edit update destroy]
  before_action :set_notifiable

  def index
    @notification_preferences = preference_scope.order(:channel)
  end

  def new
    @notification_preference = preference_scope.build
  end

  def create
    @notification_preference = preference_scope.build(notification_preference_params)

    if @notification_preference.save
      redirect_to redirect_target, notice: flash_message(:created)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @notification_preference.update(notification_preference_params)
      redirect_to redirect_target, notice: flash_message(:updated)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notification_preference.destroy
    redirect_to redirect_target, notice: flash_message(:removed)
  end

  private

  def preference_scope
    @notifiable.notification_preferences
  end

  def redirect_target
    polymorphic_path([@notifiable, :notification_preferences])
  end

  def flash_message(action)
    case action
    when :created
      "Notification preference created."
    when :updated
      "Notification preference updated."
    when :removed
      "Notification preference removed."
    else
      "Notification preference saved."
    end
  end

  def set_notifiable
    model = self.class.notifiable_model
    raise ArgumentError, "notifiable_model not configured for #{self.class.name}" unless model

    param_key = "#{model.model_name.param_key}_id"

    @notifiable = if params[param_key]
      model.find(params[param_key])
    else
      @notification_preference&.notifiable
    end

    unless @notifiable
      raise ActiveRecord::RecordNotFound, "#{model.name} not found"
    end

    instance_variable_set("@#{model.model_name.param_key}", @notifiable)
  end

  def set_notification_preference
    @notification_preference = NotificationPreference.find(params[:id]) if params[:id]
  end

  def notification_preference_params
    params.require(:notification_preference).permit(:channel, :enabled, :quiet_hours_start, :quiet_hours_end)
  end
end
