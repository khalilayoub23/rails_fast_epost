class CarriersController < ApplicationController
  def index
    @carriers = Carrier.all
    respond_to do |format|
      format.html
      format.json { render json: @carriers }
    end
  end

  def show
    @carrier = Carrier.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @carrier }
    end
  end

  def new
    @carrier = Carrier.new
  end

  def create
    @carrier = Carrier.new(carrier_params)
    if @carrier.save
      respond_to do |format|
        format.html { redirect_to @carrier, notice: "Carrier successfully created." }
        format.json { render json: @carrier, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @carrier.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @carrier = Carrier.find(params[:id])
  end

  def update
    @carrier = Carrier.find(params[:id])
    if @carrier.update(carrier_params)
      respond_to do |format|
        format.html { redirect_to @carrier, notice: "Carrier successfully updated." }
        format.json { render json: @carrier }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @carrier.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @carrier = Carrier.find(params[:id])
    # DB-level ON DELETE CASCADE handles dependent records
    @carrier.destroy
    respond_to do |format|
      format.html { redirect_to carriers_path, notice: "Carrier successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def carrier_params
    params.require(:carrier).permit(:carrier_type, :name, :email, :address)
  end
end
