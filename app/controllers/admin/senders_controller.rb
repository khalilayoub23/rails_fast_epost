module Admin
  class SendersController < ApplicationController
    before_action :require_admin!
    before_action :set_sender, only: [ :show, :edit, :update, :destroy ]

    def index
      @senders = Sender.includes(:tasks)
                       .order(created_at: :desc)

      # Filter by sender type if provided
      if params[:sender_type].present?
        @senders = @senders.where(sender_type: params[:sender_type])
      end

      # Search by name, email, or company
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @senders = @senders.where("name ILIKE ? OR email ILIKE ? OR company_name ILIKE ?",
                                   search_term, search_term, search_term)
      end
    end

    def show
      @recent_tasks = @sender.tasks.order(created_at: :desc).limit(10)
      @task_stats = {
        total: @sender.tasks.count,
        pending: @sender.tasks.where(status: :pending).count,
        in_transit: @sender.tasks.where(status: :in_transit).count,
        delivered: @sender.tasks.where(status: :delivered).count
      }
      carrier_ids = @sender.tasks.select(:carrier_id).distinct
      @carrier_performance = Carrier.where(id: carrier_ids)
      @carrier_delivery_counts = @sender.tasks.where(status: :delivered).group(:carrier_id).count
      @sender_average_carrier_score = @sender.carrier_overall_score&.round(2)
    end

    def new
      @sender = Sender.new
    end

    def create
      @sender = Sender.new(sender_params)

      if @sender.save
        redirect_to admin_sender_path(@sender), notice: "Sender created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @sender.update(sender_params)
        redirect_to admin_sender_path(@sender), notice: "Sender updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @sender.tasks.any?
        redirect_to admin_senders_path, alert: "Cannot delete sender with existing tasks."
      else
        @sender.destroy
        redirect_to admin_senders_path, notice: "Sender deleted successfully."
      end
    end

    private

    def set_sender
      @sender = Sender.find(params[:id])
    end

    def sender_params
      params.require(:sender).permit(
        :name, :email, :phone, :address, :sender_type,
        :company_name, :tax_id, :business_registration,
        :secondary_phone, :website, :notes
      )
    end

    def require_admin!
      redirect_to root_path, alert: "Access denied" unless current_user&.admin?
    end
  end
end
