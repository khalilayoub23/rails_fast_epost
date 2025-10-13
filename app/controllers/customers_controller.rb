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
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("customers_list", partial: "customers/customer_card", locals: { customer: @customer }),
            turbo_stream.update("customer_form", partial: "customers/form", locals: { customer: Customer.new }),
            turbo_stream.append("flash-messages", partial: "shared/flash_message",
                               locals: { type: :success, message: t("customers.created_successfully") })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "customer_form",
            partial: "customers/form",
            locals: { customer: @customer }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit; end

  def update
    if @customer.update(customer_params)
      respond_to do |format|
        format.html { redirect_to @customer, notice: "Customer updated." }
        format.json { render json: @customer }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@customer, partial: "customers/customer_card", locals: { customer: @customer }),
            turbo_stream.append("flash-messages", partial: "shared/flash_message",
                               locals: { type: :success, message: t("customers.updated_successfully") })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @customer,
            partial: "customers/form",
            locals: { customer: @customer }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to customers_path, notice: "Customer deleted." }
      format.json { head :no_content }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@customer),
          turbo_stream.append("flash-messages", partial: "shared/flash_message",
                             locals: { type: :success, message: t("customers.deleted_successfully") })
        ]
      end
    end
  end

  def search
    @customers = if params[:q].present?
      Customer.where("name ILIKE ?", "%#{params[:q]}%").limit(10)
    else
      Customer.limit(10)
    end

    respond_to do |format|
      format.json do
        render json: @customers.map { |c| { id: c.id, name: c.name, text: c.name } }
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "customers_list",
          partial: "customers/list",
          locals: { customers: @customers }
        )
      end
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
