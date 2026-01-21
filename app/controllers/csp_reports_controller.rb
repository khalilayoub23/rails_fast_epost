class CspReportsController < ActionController::Base
  # Browser-generated CSP violation payloads cannot send an authenticity token.
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.info("[CSP] violation: #{request.params[:csp_report].presence || request.raw_post}")
    head :no_content
  end
end
