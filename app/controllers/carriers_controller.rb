class CarriersController < ApplicationController
  def index
    @carriers = Carrier.all
  end

  def show
    @carrier = Carrier.find(params[:id])
  end

  def new
    @carrier = Carrier.new
  end

  def create
    @carrier = Carrier.new(carrier_params)
    if @carrier.save
      redirect_to @carrier, notice: "Carrier successfully created."
    else
      notice = "Carrier could not be created."
      render :new
    end
  end

  def edit
    @carrier = Carrier.find(params[:id])
  end

  def update
    @carrier = Carrier.find(params[:id])
    if @carrier.update(carrier_params)
      redirect_to @carrier, notice: "Carrier successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @carrier = Carrier.find(params[:id])
    @carrier.destroy
    redirect_to carriers_path, notice: "Carrier successfully deleted."
  end

  private

  def carrier_params
    params.require(:carrier).permit(:type, :name, :email, :address)
  end
end
