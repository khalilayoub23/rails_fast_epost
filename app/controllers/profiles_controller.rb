class ProfilesController < ApplicationController
  def show
    # Profile placeholder
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: t("profile.updated", default: "Profile updated.")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:full_name, :phone, :address, :home_address, :office_address)
  end
end
