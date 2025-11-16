class CarriersController < ApplicationController
  include Respondable

  before_action :require_admin!
  before_action :set_carrier, only: %i[show edit update destroy]

  def index
    @carriers = Carrier.all
    respond_with_index(@carriers)
  end

  def show
    respond_with_show(@carrier)
  end

  def new
    @carrier = Carrier.new
  end

  def create
    @carrier = Carrier.new(carrier_params)
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
    respond_with_update(@carrier, nil, notice: "Carrier successfully updated.") do
      carrier_params
    end
  end

  def destroy
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
