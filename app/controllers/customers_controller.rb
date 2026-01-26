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
  end

  def create
    @customer = Customer.new(customer_params)
    authorize @customer
    respond_with_create(@customer, nil, notice: "Customer created.") do
      render turbo_stream: [
        turbo_stream.prepend("customers_list", partial: "customers/customer_card", locals: { customer: @customer }),
        turbo_stream.update("customer_form", partial: "customers/form", locals: { customer: Customer.new }),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: t("customers.created_successfully") })
      ]
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
    params.require(:customer).permit(:name, :category, :address, :email, :bulk_discount, phones: [])
  end
end
