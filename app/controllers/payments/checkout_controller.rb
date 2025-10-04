module Payments
  class CheckoutController < ApplicationController
    def show
      @payment = Payment.find_by(external_id: params[:id], provider: "local")
      render plain: "Payment not found", status: :not_found and return unless @payment
    end

    def success
      render plain: "Payment success. You can customize this page."
    end

    def cancel
      render plain: "Payment canceled."
    end
  end
end
