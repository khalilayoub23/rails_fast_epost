module ControlPanel
  module Carriers
    class PayoutsController < BaseController
      def index
        @carrier = current_carrier_context
        @payouts = @carrier.carrier_payouts.order(due_at: :asc)
      end

      def show
        @carrier = current_carrier_context
        @payout = @carrier.carrier_payouts.find(params[:id])
      end
    end
  end
end
