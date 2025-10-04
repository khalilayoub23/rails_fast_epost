module Api
  module V1
    class CustomersController < BaseController
      before_action :set_customer, only: %i[show update destroy]

      def index
        render json: Customer.all
      end

      def show
        render json: @customer
      end

      def create
        customer = Customer.new(customer_params)
        if customer.save
          render json: customer, status: :created
        else
          render_errors!(customer)
        end
      end

      def update
        if @customer.update(customer_params)
          render json: @customer
        else
          render_errors!(@customer)
        end
      end

      def destroy
        @customer.destroy
        head :no_content
      end

      private

      def set_customer
        @customer = Customer.find(params[:id])
      end

      def customer_params
        params.require(:customer).permit(:name, :category, :address, :email, phones: [])
      end
    end
  end
end
