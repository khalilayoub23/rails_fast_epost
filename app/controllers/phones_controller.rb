class PhonesController < ApplicationController
  include Respondable

  before_action :set_carrier
  before_action :set_phone, only: %i[show edit update destroy]

  def index
    authorize Phone
    @phones = @carrier.phones
    respond_with_index(@phones)
  end

  def show
    authorize @phone
    respond_with_show(@phone)
  end

  def new
    @phone = @carrier.phones.new
    authorize @phone
  end

  def create
    @phone = @carrier.phones.new(phone_params)
    authorize @phone
    respond_with_create(@phone, @carrier, notice: "Phone created.") do
      render turbo_stream: [
        turbo_stream.prepend("phones_list", partial: "phones/phone_card", locals: { phone: @phone, carrier: @carrier }),
        turbo_stream.update("phone_form", ""),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("phones.created") })
      ]
    end
  end

  def edit; end

  def update
    authorize @phone
    respond_with_update(@phone, @carrier, notice: "Phone updated.", attributes: phone_params) do
      render turbo_stream: [
        turbo_stream.replace(dom_id(@phone), partial: "phones/phone_card", locals: { phone: @phone, carrier: @carrier }),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("phones.updated") })
      ]
    end
  end

  def destroy
    authorize @phone
    respond_with_destroy(@phone, carrier_phones_path(@carrier), notice: "Phone deleted.") do
      render turbo_stream: [
        turbo_stream.remove(dom_id(@phone)),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("phones.deleted") })
      ]
    end
  end

  private

  def set_carrier
    @carrier = Carrier.find(params[:carrier_id])
    authorize @carrier, :show?
  end

  def set_phone
    @phone = @carrier.phones.find(params[:id])
  end

  def phone_params
    params.require(:phone).permit(:number, :primary)
  end
end
