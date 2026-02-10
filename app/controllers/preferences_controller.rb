class PreferencesController < ApplicationController
  include Respondable

  before_action :set_carrier
  before_action :set_preference, only: %i[show edit update destroy]

  def index
    authorize Preference
    @preferences = @carrier.preference ? [ @carrier.preference ] : []
    respond_with_index(@preferences)
  end

  def show
    authorize @preference
    respond_with_show(@preference)
  end

  def new
    @preference = @carrier.build_preference
    authorize @preference
  end

  def create
    @preference = @carrier.build_preference(preference_params)
    authorize @preference
    respond_with_create(@preference, @carrier, notice: "Preference created.")
  end

  def edit; end

  def update
    authorize @preference
    respond_with_update(@preference, @carrier, notice: "Preference updated.", attributes: preference_params)
  end

  def destroy
    authorize @preference
    respond_with_destroy(@preference, carrier_preferences_path(@carrier), notice: "Preference deleted.")
  end

  private

  def set_carrier
    @carrier = Carrier.find(params[:carrier_id])
    authorize @carrier, :show?
  end

  def set_preference
    @preference = @carrier.preference || @carrier.build_preference
  end

  def preference_params
    params.require(:preference).permit(:avatar, :background_mode, bank_account: {})
  end
end
