class PreferencesController < ApplicationController
  before_action :set_carrier
  before_action :set_preference, only: %i[show edit update destroy]

  def index
    @preferences = @carrier.preference ? [ @carrier.preference ] : []
    respond_to do |format|
      format.html
      format.json { render json: @preferences }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @preference }
    end
  end

  def new
    @preference = @carrier.build_preference
  end

  def create
    @preference = @carrier.build_preference(preference_params)
    if @preference.save
      respond_to do |format|
        format.html { redirect_to [ @carrier, @preference ], notice: "Preference created." }
        format.json { render json: @preference, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @preference.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @preference.update(preference_params)
      respond_to do |format|
        format.html { redirect_to [ @carrier, @preference ], notice: "Preference updated." }
        format.json { render json: @preference }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @preference.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @preference.destroy
    respond_to do |format|
      format.html { redirect_to carrier_preferences_path(@carrier), notice: "Preference deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_carrier
    @carrier = Carrier.find(params[:carrier_id])
  end

  def set_preference
    @preference = @carrier.preference || @carrier.build_preference
  end

  def preference_params
    params.require(:preference).permit(:avatar, :background_mode, bank_account: {})
  end
end
