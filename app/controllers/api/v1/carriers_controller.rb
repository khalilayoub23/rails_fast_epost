module Api
  module V1
    class CarriersController < BaseController
      before_action :authenticate_user!
      before_action :set_carrier, only: %i[show update destroy]

      def index
        authorize Carrier
        render json: policy_scope(Carrier)
      end

      def show
        authorize @carrier
        render json: @carrier
      end

      def create
        carrier = Carrier.new(carrier_params)
        authorize carrier
        if carrier.save
          render json: carrier, status: :created
        else
          render_errors!(carrier)
        end
      end

      def update
        authorize @carrier
        if @carrier.update(carrier_params)
          render json: @carrier
        else
          render_errors!(@carrier)
        end
      end

      def destroy
        authorize @carrier
        @carrier.destroy
        head :no_content
      end

      private

      def set_carrier
        @carrier = policy_scope(Carrier).find(params[:id])
      end

      def carrier_params
        params.require(:carrier).permit(:carrier_type, :name, :email, :address)
      end
    end
  end
end
