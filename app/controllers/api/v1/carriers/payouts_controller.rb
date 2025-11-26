module Api
  module V1
    module Carriers
      class PayoutsController < BaseController
        def index
          payouts = carrier.carrier_payouts.order(due_at: :asc)
          render json: payouts.map { |payout| payout_payload(payout) }
        end

        def show
          payout = carrier.carrier_payouts.find(params[:id])
          render json: payout_payload(payout)
        end

        private

        def payout_payload(payout)
          {
            id: payout.id,
            task_id: payout.task_id,
            amount_cents: payout.amount_cents,
            currency: payout.currency,
            status: payout.status,
            due_at: payout.due_at,
            paid_at: payout.paid_at
          }
        end
      end
    end
  end
end
