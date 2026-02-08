class CustomersController < ApplicationController
  include Respondable

  before_action :set_customer, only: %i[show edit update destroy]

  def index
    authorize Customer
    @customers = policy_scope(Customer)
    respond_with_index(@customers)
  end

  def show
    authorize @customer
    respond_with_show(@customer)
  end

  def new
    @customer = Customer.new
    authorize @customer
    session[:customer_return_to] = params[:return_to] if params[:return_to].present?
  end

  def create
    @customer = Customer.new(customer_params)
    authorize @customer
    return_to = params[:return_to].presence || session.delete(:customer_return_to)

    if @customer.save
      respond_to do |format|
        format.html { redirect_to(return_to || @customer, notice: t("customers.created_successfully", default: "Customer created.")) }
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
    authorize @customer
    respond_with_update(@customer, nil, notice: "Customer updated.", attributes: customer_params) do
      render turbo_stream: [
        turbo_stream.replace(@customer, partial: "customers/customer_card", locals: { customer: @customer }),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: t("customers.updated_successfully") })
      ]
    end
  end

  def destroy
    authorize @customer
    respond_with_destroy(@customer, customers_path, notice: "Customer deleted.") do
      render turbo_stream: [
        turbo_stream.remove(@customer),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: t("customers.deleted_successfully") })
      ]
    end
  end

  def search
    authorize Customer
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
    params.require(:customer).permit(:name, :first_name, :last_name, :category, :address, :email, :bulk_discount, phones: [])
  end
end
