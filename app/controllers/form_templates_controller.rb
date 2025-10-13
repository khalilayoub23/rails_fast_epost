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
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("form_templates_list", partial: "form_templates/form_template_card", locals: { form_template: @form_template }),
            turbo_stream.update("form_template_form", ""),
            turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("form_templates.created") })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @form_template.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("form_template_form", partial: "form_templates/form", locals: { form_template: @form_template })
        end
      end
    end
  end

  def edit; end

  def update
    if @form_template.update(form_template_params)
      respond_to do |format|
        format.html { redirect_to @form_template, notice: "Form template updated." }
        format.json { render json: @form_template }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@form_template), partial: "form_templates/form_template_card", locals: { form_template: @form_template }),
            turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("form_templates.updated") })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @form_template.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@form_template), partial: "form_templates/form", locals: { form_template: @form_template })
        end
      end
    end
  end

  def destroy
    @form_template.destroy
    respond_to do |format|
      format.html { redirect_to form_templates_path, notice: "Form template deleted." }
      format.json { head :no_content }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@form_template)),
          turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("form_templates.deleted") })
        ]
      end
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
