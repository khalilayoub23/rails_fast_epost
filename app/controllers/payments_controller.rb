
class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[show edit update destroy]

  def index
    @payments = Payment.all
  end

  def show; end

  def new
    @payment = Payment.new
  end

  def create
    @payment = Payment.new(payment_params)
    if @payment.save
      redirect_to @payment, notice: "Payment successfully created."
    else
      # In test runs we want to see validation errors instead of failing silently
      render plain: @payment.errors.full_messages.join(', '), status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @payment.update(payment_params)
      redirect_to @payment, notice: "Payment successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @payment.destroy
    redirect_to payments_path, notice: "Payment successfully deleted."
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:category, :task_id, :payable_type, :payable_id, :payment_type, :interval_start, :interval_end)
  end
end
