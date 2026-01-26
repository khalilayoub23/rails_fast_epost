class CarriersController < ApplicationController
  include Respondable

  before_action :require_admin!
  before_action :set_carrier, only: %i[show edit update destroy]

  def index
    authorize Carrier
    @carriers = policy_scope(Carrier)
    respond_with_index(@carriers)
  end

  def show
    authorize @carrier
    respond_with_show(@carrier)
  end

  def new
    @carrier = Carrier.new
    authorize @carrier
  end

  def create
    @carrier = Carrier.new(carrier_params)
    authorize @carrier
    respond_with_create(@carrier, nil, notice: "Carrier successfully created.") do
      render turbo_stream: [
        turbo_stream.prepend("carriers_list", partial: "carriers/carrier_card", locals: { carrier: @carrier }),
        turbo_stream.update("carrier_form", partial: "carriers/form", locals: { carrier: Carrier.new }),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: "Carrier created successfully!" })
      ]
    end
  end

  def edit; end

  def update
    authorize @carrier
    respond_with_update(@carrier, nil, notice: "Carrier successfully updated.", attributes: carrier_params)
  end

  def destroy
    authorize @carrier
    respond_with_destroy(@carrier, carriers_path, notice: "Carrier successfully deleted.") do
      render turbo_stream: [
        turbo_stream.remove(@carrier),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: "Carrier deleted successfully!" })
      ]
    end
  end

  private

  def set_carrier
    @carrier = Carrier.find(params[:id])
  end

  def carrier_params
    params.require(:carrier).permit(:carrier_type, :name, :email, :address)
  end
end
