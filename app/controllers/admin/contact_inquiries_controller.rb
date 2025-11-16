class Admin::ContactInquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contact_inquiry, only: [:show, :update]

  def index
    @contact_inquiries = ContactInquiry.order(created_at: :desc)
    @pending_count = ContactInquiry.pending.count
    @contacted_count = ContactInquiry.contacted.count
    @resolved_count = ContactInquiry.resolved.count
  end

  def show
  end

  def update
    if @contact_inquiry.update(contact_inquiry_params)
      flash[:success] = t("admin.contact_inquiries.updated")
      redirect_to admin_contact_inquiry_path(@contact_inquiry)
    else
      flash[:error] = t("admin.contact_inquiries.update_failed")
      render :show
    end
  end

  private

  def set_contact_inquiry
    @contact_inquiry = ContactInquiry.find(params[:id])
  end

  def contact_inquiry_params
    params.require(:contact_inquiry).permit(:status, :admin_notes)
  end
end
