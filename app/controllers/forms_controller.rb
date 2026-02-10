class FormsController < ApplicationController
  include Respondable

  before_action :set_customer
  before_action :set_form, only: %i[show edit update destroy]
  before_action :set_template, only: []

  def index
    authorize Form
    @forms = @customer.forms
    respond_with_index(@forms)
  end

  def show
    authorize @form
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
    authorize @form
  end

  def create
    @form = @customer.forms.new(form_params)
    authorize @form
    respond_with_create(@form, @customer, notice: "Form created.") do
      render turbo_stream: [
        turbo_stream.prepend("forms_list", partial: "forms/form_card", locals: { form: @form, customer: @customer }),
        turbo_stream.update("form_form", ""),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("forms.created") })
      ]
    end
  end

  def edit; end

  def update
    authorize @form
    respond_with_update(@form, @customer, notice: "Form updated.", attributes: form_params) do
      render turbo_stream: [
        turbo_stream.replace(dom_id(@form), partial: "forms/form_card", locals: { form: @form, customer: @customer }),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("forms.updated") })
      ]
    end
  end

  def destroy
    authorize @form
    respond_with_destroy(@form, customer_forms_path(@customer), notice: "Form deleted.") do
      render turbo_stream: [
        turbo_stream.remove(dom_id(@form)),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("forms.deleted") })
      ]
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
    authorize @customer, :show?
  end

  def set_form
    @form = @customer.forms.find(params[:id])
  end

  def set_template
    # noop placeholder if needed later
  end

  def form_params
    params.require(:form).permit(:address, :form_default_url, :data, :form_template_id, :task_id)
  end
end
