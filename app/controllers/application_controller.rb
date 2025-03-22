class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :allow_github_codespaces

  private

  def allow_github_codespaces
    if Rails.env.development?
      request.headers["HTTP_ORIGIN"] = request.base_url if request.headers["HTTP_ORIGIN"].nil?
    end
  end
end
