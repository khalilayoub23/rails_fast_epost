module Admin
  class MessengersController < ApplicationController
    before_action :require_admin_or_manager!
    before_action :set_messenger, only: [ :show, :edit, :update, :destroy, :update_status, :update_location ]

    def index
      @messengers = Messenger.includes(:carrier, :tasks)
                             .order(created_at: :desc)

      # Filter by status
      if params[:status].present?
        @messengers = @messengers.where(status: params[:status])
      end

      # Filter by carrier
      if params[:carrier_id].present?
        @messengers = @messengers.where(carrier_id: params[:carrier_id])
      end

      # Filter by vehicle type
      if params[:vehicle_type].present?
        @messengers = @messengers.where(vehicle_type: params[:vehicle_type])
      end

      # Search by name, email, or employee ID
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @messengers = @messengers.where("name ILIKE ? OR email ILIKE ? OR employee_id ILIKE ?",
                                         search_term, search_term, search_term)
      end

      # Stats for dashboard
      @stats = {
        total: Messenger.count,
        available: Messenger.available.count,
        busy: Messenger.busy.count,
        offline: Messenger.offline.count,
        avg_on_time_rate: Messenger.average(:on_time_rate).to_f
      }
    end

    def show
      @recent_tasks = @messenger.tasks.order(created_at: :desc).limit(10)
      @today_tasks = @messenger.tasks.where("created_at >= ?", Time.current.beginning_of_day)
      @task_stats = {
        total: @messenger.tasks.count,
        today: @today_tasks.count,
        pending: @messenger.tasks.where(status: :pending).count,
        in_transit: @messenger.tasks.where(status: :in_transit).count,
        delivered: @messenger.tasks.where(status: :delivered).count
      }
    end

    def new
      @messenger = Messenger.new
      @carriers = Carrier.order(:name)
    end

    def create
      @messenger = Messenger.new(messenger_params)

      if @messenger.save
        redirect_to admin_messenger_path(@messenger), notice: "Messenger created successfully."
      else
        @carriers = Carrier.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @carriers = Carrier.order(:name)
    end

    def update
      if @messenger.update(messenger_params)
        redirect_to admin_messenger_path(@messenger), notice: "Messenger updated successfully."
      else
        @carriers = Carrier.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @messenger.tasks.any?
        redirect_to admin_messengers_path, alert: "Cannot delete messenger with existing tasks."
      else
        @messenger.destroy
        redirect_to admin_messengers_path, notice: "Messenger deleted successfully."
      end
    end

    # PATCH /admin/messengers/:id/update_status
    def update_status
      new_status = params[:status]

      if Messenger.statuses.keys.include?(new_status)
        case new_status
        when "available"
          @messenger.mark_available!
        when "busy"
          @messenger.mark_busy!
        when "offline"
          @messenger.mark_offline!
        end

        respond_to do |format|
          format.html { redirect_to admin_messenger_path(@messenger), notice: "Status updated to #{new_status}." }
          format.json { render json: { status: new_status, messenger: @messenger } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_messenger_path(@messenger), alert: "Invalid status." }
          format.json { render json: { error: "Invalid status" }, status: :unprocessable_entity }
        end
      end
    end

    # PATCH /admin/messengers/:id/update_location
    def update_location
      latitude = params[:latitude]
      longitude = params[:longitude]

      if latitude.present? && longitude.present?
        @messenger.update_location!(latitude: latitude.to_f, longitude: longitude.to_f)

        respond_to do |format|
          format.html { redirect_to admin_messenger_path(@messenger), notice: "Location updated." }
          format.json { render json: { location: @messenger.current_location } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_messenger_path(@messenger), alert: "Invalid location data." }
          format.json { render json: { error: "Invalid location data" }, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_messenger
      @messenger = Messenger.find(params[:id])
    end

    def messenger_params
      params.require(:messenger).permit(
        :name, :email, :phone, :carrier_id, :status, :vehicle_type,
        :license_plate, :license_number, :employee_id,
        :secondary_phone, :emergency_contact, :notes,
        working_hours: [ :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday ]
      )
    end

    def require_admin_or_manager!
      unless current_user&.admin? || current_user&.manager?
        redirect_to root_path, alert: "Access denied"
      end
    end
  end
end
