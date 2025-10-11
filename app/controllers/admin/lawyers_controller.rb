# Admin Lawyers Controller
class Admin::LawyersController < ApplicationController
  before_action :set_lawyer, only: [ :show, :edit, :update, :destroy, :activate, :deactivate ]

  # GET /admin/lawyers
  def index
    @lawyers = Lawyer.all.order(created_at: :desc)

    # Filter by active status
    @lawyers = @lawyers.active if params[:status] == "active"
    @lawyers = @lawyers.inactive if params[:status] == "inactive"

    # Filter by specialization
    @lawyers = @lawyers.by_specialization(params[:specialization]) if params[:specialization].present?

    # Search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @lawyers = @lawyers.where(
        "name ILIKE ? OR email ILIKE ? OR license_number ILIKE ?",
        search_term, search_term, search_term
      )
    end

    @lawyers = @lawyers.page(params[:page]).per(20) if defined?(Kaminari)
  end

  # GET /admin/lawyers/:id
  def show
    @tasks = @lawyer.tasks.order(created_at: :desc).limit(10)
  end

  # GET /admin/lawyers/new
  def new
    @lawyer = Lawyer.new
  end

  # GET /admin/lawyers/:id/edit
  def edit
  end

  # POST /admin/lawyers
  def create
    @lawyer = Lawyer.new(lawyer_params)

    if @lawyer.save
      redirect_to admin_lawyer_path(@lawyer), notice: "Lawyer successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/lawyers/:id
  def update
    if @lawyer.update(lawyer_params)
      redirect_to admin_lawyer_path(@lawyer), notice: "Lawyer successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/lawyers/:id
  def destroy
    @lawyer.destroy!
    redirect_to admin_lawyers_path, notice: "Lawyer successfully deleted."
  end

  # PATCH /admin/lawyers/:id/activate
  def activate
    @lawyer.activate!
    redirect_to admin_lawyer_path(@lawyer), notice: "Lawyer activated successfully."
  end

  # PATCH /admin/lawyers/:id/deactivate
  def deactivate
    @lawyer.deactivate!
    redirect_to admin_lawyer_path(@lawyer), notice: "Lawyer deactivated successfully."
  end

  private

  def set_lawyer
    @lawyer = Lawyer.find(params[:id])
  end

  def lawyer_params
    params.require(:lawyer).permit(
      :name,
      :email,
      :phone,
      :license_number,
      :specialization,
      :bar_association,
      :notes,
      :active
    )
  end
end
