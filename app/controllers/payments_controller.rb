
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
    if stripe_payment_request?
      return create_stripe_payment
    end

    @payment = Payment.new(payment_params)
    if @payment.save
      respond_to_create_success
    else
      respond_to_create_failure
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
                                    :provider, :gateway_status, :amount_cents, :amount, :currency, metadata: {})
  end

  def stripe_payment_request?
    payment_params[:provider].to_s.casecmp("stripe").zero?
  end

  def create_stripe_payment
    @payment = Gateways::StripeGateway.create_payment!(
      amount_cents: stripe_amount_cents,
      currency: payment_params[:currency].presence || "USD",
      task: Task.find(payment_params[:task_id]),
      payable: stripe_payable,
      metadata: stripe_metadata
    )
    respond_to_create_success
  rescue => e
    Rails.logger.error("Stripe payment creation failed: #{e.message}")
    respond_to_stripe_error(e)
  end

  def stripe_amount_cents
    cents = payment_params[:amount_cents].presence
    return cents.to_i if cents

    amount = payment_params[:amount].presence
    raise ArgumentError, "Amount is required for Stripe payments" if amount.blank?

    (BigDecimal(amount.to_s) * 100).to_i
  end

  def stripe_payable
    type = payment_params[:payable_type].presence
    id = payment_params[:payable_id].presence
    raise ArgumentError, "Payable reference is required" if type.blank? || id.blank?

    klass = type.safe_constantize
    raise ArgumentError, "Unknown payable type" if klass.blank?

    klass.find(id)
  end

  def stripe_metadata
    base = payment_params[:metadata].respond_to?(:to_h) ? payment_params[:metadata].to_h : {}
    base.merge(
      "success_url" => pay_success_url,
      "cancel_url" => pay_cancel_url,
      "created_by_user_id" => current_user.id,
      "creator_email" => current_user.email
    )
  end

  def respond_to_create_success
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
  end

  def respond_to_create_failure
    respond_to do |format|
      format.html { render plain: @payment.errors.full_messages.join(", "), status: :unprocessable_entity }
      format.json { render json: { errors: @payment.errors.full_messages }, status: :unprocessable_entity }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("payment_form", partial: "payments/form", locals: { payment: @payment })
      end
    end
  end

  def respond_to_stripe_error(error)
    respond_to do |format|
      format.html { redirect_to new_payment_path, alert: error.message }
      format.json { render json: { error: error.message }, status: :unprocessable_entity }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :alert, message: error.message })
      end
    end
  end
end
