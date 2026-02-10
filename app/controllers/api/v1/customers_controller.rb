module Api
  module V1
    class CustomersController < BaseController
      before_action :authenticate_user!
      before_action :set_customer, only: %i[show update destroy]

      def index
        authorize Customer
        render json: policy_scope(Customer)
      end

      def show
        authorize @customer
        render json: @customer
      end

      def create
        customer = Customer.new(customer_params)
        authorize customer
        if customer.save
          render json: customer, status: :created
        else
          render_errors!(customer)
        end
      end

      def update
        authorize @customer
        if @customer.update(customer_params)
          render json: @customer
        else
          render_errors!(@customer)
        end
      end

      def destroy
        authorize @customer
        @customer.destroy
        head :no_content
      end

      private

      def set_customer
        @customer = policy_scope(Customer).find(params[:id])
      end

      def customer_params
        params.require(:customer).permit(:name, :category, :address, :email, phones: [])
      end
    end
  end
end
