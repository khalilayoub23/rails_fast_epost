module Api
  module V1
    module Carriers
      class BaseController < ApplicationController
        protect_from_forgery with: :null_session
        before_action :authenticate_user!
        before_action :require_carrier_membership!

        private

        def carrier
          current_carrier_context
        end
      end
    end
  end
end
