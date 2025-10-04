class FormTemplatesController < ApplicationController
  before_action :set_form_template, only: %i[show edit update destroy]

  def index
    @form_templates = FormTemplate.all
    respond_to do |format|
      format.html
      format.json { render json: @form_templates }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @form_template }
      format.pdf do
        sample = sample_data(@form_template.schema || {})
        pdf = Pdf::TemplateRenderer.render(schema: @form_template.schema || {}, data: sample)
        send_data pdf, filename: "template-#{@form_template.id}.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  def new
    @form_template = FormTemplate.new
  end

  def create
    @form_template = FormTemplate.new(form_template_params)
    if @form_template.save
      respond_to do |format|
        format.html { redirect_to @form_template, notice: "Form template created." }
        format.json { render json: @form_template, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @form_template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @form_template.update(form_template_params)
      respond_to do |format|
        format.html { redirect_to @form_template, notice: "Form template updated." }
        format.json { render json: @form_template }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @form_template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @form_template.destroy
    respond_to do |format|
      format.html { redirect_to form_templates_path, notice: "Form template deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_form_template
    @form_template = FormTemplate.find(params[:id])
  end

  def sample_data(schema)
    fields = Array(schema["fields"]) || []
    fields.each_with_object({}) do |f, h|
      h[f["name"].to_s] = "Sample"
    end
  end

  def form_template_params
    params.require(:form_template).permit(:carrier_id, :customer_id, :schema)
  end
end
