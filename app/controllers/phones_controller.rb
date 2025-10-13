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
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("phones_list", partial: "phones/phone_card", locals: { phone: @phone, carrier: @carrier }),
            turbo_stream.update("phone_form", ""),
            turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("phones.created") })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @phone.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("phone_form", partial: "phones/form", locals: { phone: @phone, carrier: @carrier })
        end
      end
    end
  end

  def edit; end

  def update
    if @phone.update(phone_params)
      respond_to do |format|
        format.html { redirect_to [ @carrier, @phone ], notice: "Phone updated." }
        format.json { render json: @phone }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@phone), partial: "phones/phone_card", locals: { phone: @phone, carrier: @carrier }),
            turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("phones.updated") })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @phone.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@phone), partial: "phones/form", locals: { phone: @phone, carrier: @carrier })
        end
      end
    end
  end

  def destroy
    @phone.destroy
    respond_to do |format|
      format.html { redirect_to carrier_phones_path(@carrier), notice: "Phone deleted." }
      format.json { head :no_content }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@phone)),
          turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("phones.deleted") })
        ]
      end
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
