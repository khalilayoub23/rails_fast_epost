class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'public'
  
  def home
  end

  def about
  end

  def services
  end

  def contact
  end

  def track_parcel
  end

  def law_firms
  end

  def ecommerce
  end

  def privacy_policy
  end
end
