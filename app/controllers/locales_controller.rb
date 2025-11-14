class LocalesController < ApplicationController
  skip_before_action :authenticate_user!
  def update
    locale = params[:id].to_s.downcase
    unless I18n.available_locales.map(&:to_s).include?(locale)
      redirect_back(fallback_location: root_path, alert: "Unsupported locale") and return
    end
    cookies[:locale] = { value: locale, expires: 1.year.from_now }
    session[:locale] = locale
    redirect_back(fallback_location: root_path)
  end
end
