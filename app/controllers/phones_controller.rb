class PhonesController < ApplicationController
  include Respondable

  before_action :set_carrier
  before_action :set_phone, only: %i[show edit update destroy]

  def index
    @phones = @carrier.phones
    respond_with_index(@phones)
  end

  def show
    respond_with_show(@phone)
  end

  def new
    @phone = @carrier.phones.new
  end

  def create
    @phone = @carrier.phones.new(phone_params)
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
    respond_with_update(@phone, @carrier, notice: "Phone updated.") do
      render turbo_stream: [
        turbo_stream.replace(dom_id(@phone), partial: "phones/phone_card", locals: { phone: @phone, carrier: @carrier }),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("phones.updated") })
      ]
      phone_params
    end
  end

  def destroy
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
  end

  def set_phone
    @phone = @carrier.phones.find(params[:id])
  end

  def phone_params
    params.require(:phone).permit(:number, :primary)
  end
end
