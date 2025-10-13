
class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[show edit update destroy refund capture cancel sync]
  before_action :require_manager!, only: %i[new create edit update destroy refund capture cancel sync]

  def index
    @payments = Payment.all
    respond_to do |format|
      format.html
      format.json { render json: @payments }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @payment }
    end
  end

  def new
    @payment = Payment.new
  end

  def create
    @payment = Payment.new(payment_params)
    if @payment.save
      respond_to do |format|
        format.html { redirect_to @payment, notice: "Payment successfully created." }
        format.json { render json: @payment, status: :created }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("payments_list", partial: "payments/payment_card", locals: { payment: @payment }),
            turbo_stream.update("payment_form", ""),
            turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("payments.created") })
          ]
        end
      end
    else
      # In test runs we want to see validation errors instead of failing silently
      respond_to do |format|
        format.html { render plain: @payment.errors.full_messages.join(", "), status: :unprocessable_entity }
        format.json { render json: { errors: @payment.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("payment_form", partial: "payments/form", locals: { payment: @payment })
        end
      end
    end
  end

  def edit; end

  def update
    if @payment.update(payment_params)
      respond_to do |format|
        format.html { redirect_to @payment, notice: "Payment successfully updated." }
        format.json { render json: @payment }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@payment), partial: "payments/payment_card", locals: { payment: @payment }),
            turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("payments.updated") })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @payment.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@payment), partial: "payments/form", locals: { payment: @payment })
        end
      end
    end
  end

  def destroy
    @payment.destroy
    respond_to do |format|
      format.html { redirect_to payments_path, notice: "Payment successfully deleted." }
      format.json { head :no_content }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@payment)),
          turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("payments.deleted") })
        ]
      end
    end
  end

  # UI: POST /payments/:id/refund
  def refund
    if @payment.provider == "stripe"
      amount_cents = params[:amount_cents]
      reason = params[:reason]
      Gateways::StripeGateway.refund!(payment: @payment, amount_cents: amount_cents&.to_i, reason: reason)
      redirect_to @payment, notice: "Refund initiated"
    else
      redirect_to @payment, alert: "Unsupported provider"
    end
  rescue => e
    redirect_to @payment, alert: e.message
  end

  def capture
    if @payment.provider == "stripe"
      Gateways::StripeGateway.capture!(payment: @payment)
      redirect_to @payment, notice: "Capture succeeded"
    else
      redirect_to @payment, alert: "Unsupported provider"
    end
  rescue => e
    redirect_to @payment, alert: e.message
  end

  def cancel
    if @payment.provider == "stripe"
      Gateways::StripeGateway.cancel!(payment: @payment)
      redirect_to @payment, notice: "Payment canceled"
    else
      redirect_to @payment, alert: "Unsupported provider"
    end
  rescue => e
    redirect_to @payment, alert: e.message
  end

  def sync
    if @payment.provider == "stripe"
      Gateways::StripeGateway.sync!(payment: @payment)
      redirect_to @payment, notice: "Payment synced"
    else
      redirect_to @payment, alert: "Unsupported provider"
    end
  rescue => e
    redirect_to @payment, alert: e.message
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:category, :task_id, :payable_type, :payable_id, :payment_type, :interval_start, :interval_end,
                                    :provider, :gateway_status, :amount_cents, :currency)
  end
end
