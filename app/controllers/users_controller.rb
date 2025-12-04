class UsersController < ApplicationController
  def update_signature
    @user = User.find(params[:id])
    authorize @user, :update_signature?

    signature_file = params.dig(:user, :saved_signature)
    if signature_file.blank?
      redirect_back fallback_location: edit_user_registration_path, alert: t("users.signature.missing", default: "Please upload a signature file.")
      return
    end

    SignatureService.new.save_user_signature(user: @user, signature_file: signature_file)
    redirect_back fallback_location: edit_user_registration_path, notice: t("users.signature.updated", default: "Signature saved successfully.")
  rescue Pundit::NotAuthorizedError => e
    raise e
  rescue StandardError => e
    redirect_back fallback_location: edit_user_registration_path, alert: e.message
  end
end
