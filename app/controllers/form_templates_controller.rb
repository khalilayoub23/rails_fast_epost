class FormTemplatesController < ApplicationController
  include Respondable

  before_action :set_form_template, only: %i[show edit update destroy]

  def index
    authorize FormTemplate
    @form_templates = policy_scope(FormTemplate)
    respond_with_index(@form_templates)
  end

  def show
    authorize @form_template
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
    authorize @form_template
  end

  def create
    @form_template = FormTemplate.new(form_template_params)
    authorize @form_template
    respond_with_create(@form_template, nil, notice: "Form template created.") do
      render turbo_stream: [
        turbo_stream.prepend("form_templates_list", partial: "form_templates/form_template_card", locals: { form_template: @form_template }),
        turbo_stream.update("form_template_form", ""),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("form_templates.created") })
      ]
    end
  end

  def edit; end

  def update
    authorize @form_template
    respond_with_update(@form_template, nil, notice: "Form template updated.", attributes: form_template_params) do
      render turbo_stream: [
        turbo_stream.replace(dom_id(@form_template), partial: "form_templates/form_template_card", locals: { form_template: @form_template }),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("form_templates.updated") })
      ]
    end
  end

  def destroy
    authorize @form_template
    respond_with_destroy(@form_template, form_templates_path, notice: "Form template deleted.") do
      render turbo_stream: [
        turbo_stream.remove(dom_id(@form_template)),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("form_templates.deleted") })
      ]
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
