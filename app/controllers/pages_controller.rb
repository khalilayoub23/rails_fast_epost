class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  layout "public"

  def home
    @stats = {
      total_deliveries: Task.delivered.count,
      active_shipments: Task.in_transit.count + Task.pending.count,
      total_customers: Customer.count,
      carriers_network: Carrier.count
    }
  end

  def about
  end

  def services
  end

  def contact
    @contact = ContactInquiry.new

    return unless request.post?

    @contact.assign_attributes(contact_inquiry_params)

    if @contact.save
      flash[:notice] = "Thank you! We'll get back to you within 24 hours."
      redirect_to pages_contact_path
    else
      flash.now[:alert] = "Please fix the errors below."
      render :contact, status: :unprocessable_entity
    end
  end

  def track_parcel
    if params[:tracking_number].present?
      @task = Task.find_by(barcode: params[:tracking_number].upcase.strip)
      if @task.nil?
        flash.now[:alert] = "Tracking number not found. Please check and try again."
      end
    end
  end

  def law_firms
  end

  def ecommerce
  end

  def privacy_policy
  end

  private

  def contact_inquiry_params
    params.require(:contact_inquiry).permit(:name, :email, :phone, :service, :message)
  end
end
