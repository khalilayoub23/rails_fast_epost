module Api
  module V1
    class CarriersController < BaseController
      before_action :set_carrier, only: %i[show update destroy]

      def index
        render json: Carrier.all
      end

      def show
        render json: @carrier
      end

      def create
        carrier = Carrier.new(carrier_params)
        if carrier.save
          render json: carrier, status: :created
        else
          render_errors!(carrier)
        end
      end

      def update
        if @carrier.update(carrier_params)
          render json: @carrier
        else
          render_errors!(@carrier)
        end
      end

      def destroy
        @carrier.destroy
        head :no_content
      end

      private

      def set_carrier
        @carrier = Carrier.find(params[:id])
      end

      def carrier_params
        params.require(:carrier).permit(:carrier_type, :name, :email, :address)
      end
    end
  end
end
