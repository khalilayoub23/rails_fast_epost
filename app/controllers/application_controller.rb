class ApplicationController < ActionController::Base
  layout :determine_layout
  include TurboNativeSupport
  include Pundit::Authorization

  protect_from_forgery with: :exception
  before_action :set_locale
  before_action :allow_github_codespaces
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, if: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_current_attributes
  helper_method :stripe_publishable_key, :current_carrier_context
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Add custom data to logs (used by Lograge)
  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_user&.id
    payload[:ip] = request.remote_ip
    payload[:host] = request.host
  end

  # Ensure Devise always returns to the sign-in screen after logout, even
  # when locale-scoped routes are used.
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path(locale: nil)
  end

  def after_sign_in_path_for(resource)
    # Sync the current active locale to the user's profile if they differ.
    # This ensures that the language the user is currently viewing (from params, cookie, or headers)
    # becomes their saved preference upon login.
    if resource.respond_to?(:preferred_language)
      current_locale = I18n.locale.to_s
      if I18n.available_locales.map(&:to_s).include?(current_locale)
        if resource.preferred_language != current_locale
          resource.update_column(:preferred_language, current_locale)
        end
      end
    end

    stored_location_for(resource) || default_signed_in_path(resource)
  end

  def after_sign_up_path_for(resource)
    default_signed_in_path(resource)
  end

  private

  def determine_layout
    return "public" if devise_controller?

    "application"
  end

  def allow_github_codespaces
    if Rails.env.development?
      request.headers["HTTP_ORIGIN"] = request.base_url if request.headers["HTTP_ORIGIN"].nil?
    end
  end

  def stripe_publishable_key
    Rails.configuration.x.try(:stripe).try(:publishable_key)
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end

  def require_manager!
    return if current_user&.manager?

    respond_to do |format|
      format.html { redirect_to root_path, alert: t("messages.unauthorized") }
      format.json { render json: { error: t("messages.unauthorized") }, status: :forbidden }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "flash_messages",
          partial: "shared/flash_message",
          locals: { type: :alert, message: t("messages.unauthorized") }
        ), status: :forbidden
      end
      format.any { head :forbidden }
    end
  end

  def require_carrier_membership!
    return if current_carrier_context.present?

    message = t("messages.no_carrier_membership", default: "You are not assigned to any carriers yet.")
    respond_to do |format|
      format.json { render json: { error: message }, status: :forbidden }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "flash_messages",
          partial: "shared/flash_message",
          locals: { type: :alert, message: message }
        ), status: :forbidden
      end
      format.any { redirect_to root_path, alert: message }
    end
  end

  # Set Current.user for use in models/jobs
  def set_current_attributes
    Current.user = current_user
  end

  def user_not_authorized
    message = t("messages.unauthorized", default: "You are not authorized to perform this action.")
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: message }
      format.json { render json: { error: message }, status: :forbidden }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "flash_messages",
          partial: "shared/flash_message",
          locals: { type: :alert, message: message }
        ), status: :forbidden
      end
      format.any { head :forbidden }
    end
  end

  # Set locale based on user preference, params, session, or browser
  def set_locale
    locale = extract_locale
    I18n.locale = locale
    
    if locale != session[:locale]
      session[:locale] = locale
    end
    
    # Update user preference if they explicitly switched via params
    if params[:locale].present? && current_user && current_user.respond_to?(:preferred_language) && current_user.preferred_language != locale.to_s
      current_user.update_column(:preferred_language, locale)
    end
  end

  def default_signed_in_path(resource)
    dashboard_path
  end

  def extract_locale
    # 1. Check URL params (highest priority)
    parsed_locale = parse_locale(params[:locale])
    return parsed_locale if parsed_locale

    # 2. Check current user preference
    if current_user&.preferred_language.present?
      parsed_locale = parse_locale(current_user.preferred_language)
      return parsed_locale if parsed_locale
    end

    # 3. Check session
    parsed_locale = parse_locale(session[:locale])
    return parsed_locale if parsed_locale

    # 4. Check cookie
    parsed_locale = parse_locale(cookies[:locale])
    return parsed_locale if parsed_locale

    # 5. Check browser Accept-Language header
    parsed_locale = parse_locale_from_header
    return parsed_locale if parsed_locale

    # 6. Default locale
    I18n.default_locale
  end

  def parse_locale(locale_string)
    return nil if locale_string.blank?
    locale = locale_string.to_sym
    I18n.available_locales.include?(locale) ? locale : nil
  end

  def parse_locale_from_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    accepted = request.env["HTTP_ACCEPT_LANGUAGE"]
      .split(",")
      .map { |l| l.split(";").first.strip.split("-").first.to_sym }
      .find { |l| I18n.available_locales.include?(l) }

    accepted
  end

  protected

  # Permit additional Devise params so user roles/types persist on sign up & edit
  def configure_permitted_parameters
    extra_keys = [ :full_name, :phone, :role, :user_type, :preferred_language ]

    devise_parameter_sanitizer.permit(:sign_up, keys: extra_keys)
    devise_parameter_sanitizer.permit(:account_update, keys: extra_keys)
  end

  def current_carrier_context
    return @current_carrier_context if defined?(@current_carrier_context)
    return nil unless current_user

    scope = current_user.carriers
    return @current_carrier_context = nil if scope.none?

    requested_id = params[:carrier_id] || session[:carrier_context_id]
    carrier = scope.find_by(id: requested_id)
    carrier ||= scope.first

    session[:carrier_context_id] = carrier.id if carrier
    @current_carrier_context = carrier
  end
end
