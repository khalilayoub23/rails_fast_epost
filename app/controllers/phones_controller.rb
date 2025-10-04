class PhonesController < ApplicationController
  before_action :set_carrier
  before_action :set_phone, only: %i[show edit update destroy]

  def index
    @phones = @carrier.phones
    respond_to do |format|
      format.html
      format.json { render json: @phones }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @phone }
    end
  end

  def new
    @phone = @carrier.phones.new
  end

  def create
    @phone = @carrier.phones.new(phone_params)
    if @phone.save
      respond_to do |format|
        format.html { redirect_to [ @carrier, @phone ], notice: "Phone created." }
        format.json { render json: @phone, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @phone.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @phone.update(phone_params)
      respond_to do |format|
        format.html { redirect_to [ @carrier, @phone ], notice: "Phone updated." }
        format.json { render json: @phone }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @phone.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @phone.destroy
    respond_to do |format|
      format.html { redirect_to carrier_phones_path(@carrier), notice: "Phone deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_carrier
    @carrier = Carrier.find(params[:carrier_id])
  end

  def set_phone
    @phone = @carrier.phones.find(params[:id])
  end

  def phone_params
    params.require(:phone).permit(:number, :primary)
  end
end
