class FormsController < ApplicationController
  before_action :set_customer
  before_action :set_form, only: %i[show edit update destroy]
  before_action :set_template, only: []

  def index
    @forms = @customer.forms
    respond_to do |format|
      format.html
      format.json { render json: @forms }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @form }
      format.pdf do
        template = @form.form_template || FormTemplate.find_by(customer_id: @customer.id)
        if template
          pdf = Pdf::TemplateRenderer.render(schema: template.schema, data: @form.data)
          send_data pdf, filename: "form-#{@form.id}.pdf", type: "application/pdf", disposition: "inline"
        else
          render plain: "No template", status: :not_found
        end
      end
    end
  end

  def new
    @form = @customer.forms.new
  end

  def create
    @form = @customer.forms.new(form_params)
    if @form.save
      respond_to do |format|
        format.html { redirect_to [ @customer, @form ], notice: "Form created." }
        format.json { render json: @form, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @form.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @form.update(form_params)
      respond_to do |format|
        format.html { redirect_to [ @customer, @form ], notice: "Form updated." }
        format.json { render json: @form }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @form.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @form.destroy
    respond_to do |format|
      format.html { redirect_to customer_forms_path(@customer), notice: "Form deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_form
    @form = @customer.forms.find(params[:id])
  end

  def set_template
    # noop placeholder if needed later
  end

  def form_params
    params.require(:form).permit(:address, :form_default_url, :data, :form_template_id)
  end
end
