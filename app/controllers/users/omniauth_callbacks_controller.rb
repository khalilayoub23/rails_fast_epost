# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      handle_auth "Google"
    end

    def facebook
      handle_auth "Facebook"
    end

    def failure
      redirect_to new_user_session_path, alert: failure_message
    end

    private

    def handle_auth(kind)
      @user = User.from_omniauth(request.env["omniauth.auth"])

      if @user&.persisted?
        set_flash_message!(:notice, :success, kind: kind)
        sign_in_and_redirect @user, event: :authentication
      else
        flash[:alert] = failure_message(kind)
        redirect_to new_user_registration_url
      end
    rescue StandardError => e
      Rails.logger.error("OmniAuth #{kind} failure: #{e.message}")
      redirect_to new_user_session_path, alert: failure_message(kind)
    end

    def failure_message(kind = "OmniAuth")
      I18n.t("devise.omniauth_callbacks.failure", kind: kind, reason: I18n.t("errors.messages.auth_failure", default: "please try again"))
    end
  end
end
