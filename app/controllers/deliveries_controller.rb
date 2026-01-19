class DeliveriesController < ApplicationController
  before_action :set_delivery, only: %i[show edit update destroy]
  before_action :load_form_collections, only: %i[new create edit update]

  def index
    authorize Delivery
    scope = policy_scope(Delivery).includes(:sender, :courier, :recipient).order(created_at: :desc)
    @delivery_filters = delivery_filter_params
    @filter_sender_options = User.where(user_type: User.user_types.slice(:sender, :lawyer, :ecommerce_seller).values).order(:full_name)
    @filter_courier_options = User.where(user_type: User.user_types[:courier]).order(:full_name)
    @filter_recipient_options = User.where(user_type: User.user_types[:recipient]).order(:full_name)
    @deliveries = apply_filters(scope)
  end

  def show
    authorize @delivery
    @signature_progress = @delivery.signature_progress
  end

  def new
    @delivery = Delivery.new
    authorize @delivery
  end

  def create
    @delivery = Delivery.new(delivery_params)
    authorize @delivery

    if @delivery.save
      ProcessDeliveryPdfJob.perform_later(@delivery.id)
      redirect_to @delivery, notice: t("deliveries.created", default: "Delivery created. PDF processing started.")
      puts "Delivery ##{@delivery.id} created by User ##{current_user.id}"
    else
      # If the user didn't provide a case number, clear the auto-generated one
      # to avoid potential collisions if they resubmit after a delay.
      @delivery.case_number = nil if delivery_params[:case_number].blank?

      puts "Failed to create Delivery by User ##{current_user.id}: #{@delivery.errors.full_messages.to_sentence}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @delivery
  end

  def update
    authorize @delivery

    if @delivery.update(delivery_params)
      redirect_to @delivery, notice: t("deliveries.updated", default: "Delivery updated.")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @delivery
    if @delivery.destroy
      redirect_to deliveries_path, notice: t("deliveries.deleted", default: "Delivery removed.")
    else
      redirect_to @delivery, alert: @delivery.errors.full_messages.to_sentence
    end
  end

  private

  def set_delivery
    @delivery = policy_scope(Delivery).find(params[:id])
  end

  def delivery_params
    params.require(:delivery).permit(:sender_id, :recipient_id, :courier_id, :case_number, :notes, :original_court_pdf)
  end

  def load_form_collections
    @sender_options = User.where(user_type: User.user_types.slice(:sender, :lawyer).values)
      .order(:full_name)
    @courier_options = User.where(user_type: User.user_types[:courier]).order(:full_name)
    @recipient_options = User.where(user_type: User.user_types[:recipient]).order(:full_name)
  end

  def delivery_filter_params
    params.fetch(:delivery_filter, {}).permit(:status, :courier_id, :sender_id, :recipient_id)
  end

  def apply_filters(scope)
    filters = delivery_filter_params
    scope = scope.where(status: filters[:status]) if filters[:status].present?
    scope = scope.where(courier_id: filters[:courier_id]) if filters[:courier_id].present?
    scope = scope.where(sender_id: filters[:sender_id]) if filters[:sender_id].present?
    scope = scope.where(recipient_id: filters[:recipient_id]) if filters[:recipient_id].present?
    scope
  end
end
