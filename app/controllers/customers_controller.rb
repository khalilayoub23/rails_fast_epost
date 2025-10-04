class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @customers = Customer.all
    respond_to do |format|
      format.html
      format.json { render json: @customers }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @customer }
    end
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)
    if @customer.save
      respond_to do |format|
        format.html { redirect_to @customer, notice: "Customer created." }
        format.json { render json: @customer, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @customer.update(customer_params)
      respond_to do |format|
        format.html { redirect_to @customer, notice: "Customer updated." }
        format.json { render json: @customer }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to customers_path, notice: "Customer deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :category, :address, :email, phones: [])
  end
end
