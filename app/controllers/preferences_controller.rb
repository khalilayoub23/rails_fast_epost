class PreferencesController < ApplicationController
  include Respondable

  before_action :set_carrier
  before_action :set_preference, only: %i[show edit update destroy]

  def index
    @preferences = @carrier.preference ? [ @carrier.preference ] : []
    respond_with_index(@preferences)
  end

  def show
    respond_with_show(@preference)
  end

  def new
    @preference = @carrier.build_preference
  end

  def create
    @preference = @carrier.build_preference(preference_params)
    respond_with_create(@preference, @carrier, notice: "Preference created.")
  end

  def edit; end

  def update
    respond_with_update(@preference, @carrier, notice: "Preference updated.", attributes: preference_params)
  end

  def destroy
    respond_with_destroy(@preference, carrier_preferences_path(@carrier), notice: "Preference deleted.")
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
