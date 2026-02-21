module Api
  module V1
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      private

      def render_errors!(record, status = :unprocessable_entity)
        render json: { errors: record.errors.full_messages }, status: status
      end
    end
  end
end
