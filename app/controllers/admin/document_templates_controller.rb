class Admin::DocumentTemplatesController < ApplicationController
  before_action :require_admin_or_lawyer!
  before_action :set_document_template, only: [ :show, :edit, :update, :destroy, :download, :preview, :new_generate, :generate ]

  # GET /admin/document_templates
  def index
    @document_templates = DocumentTemplate.recent

    # Filter by category if provided
    @document_templates = @document_templates.by_category(params[:category]) if params[:category].present?

    # Filter by template type if provided
    @document_templates = @document_templates.by_type(params[:template_type]) if params[:template_type].present?

    # Filter by active status
    @document_templates = @document_templates.active_templates if params[:active] == "true"
  end

  # GET /admin/document_templates/:id
  def show
  end

  # GET /admin/document_templates/new
  def new
    @document_template = DocumentTemplate.new
  end

  # POST /admin/document_templates
  def create
    @document_template = DocumentTemplate.new(document_template_params)

    if @document_template.save
      # Extract variables from content if it's a Prawn template
      @document_template.update_variables_schema! if @document_template.prawn_template? && @document_template.content.present?

      redirect_to admin_document_template_path(@document_template), notice: "Document template successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/document_templates/:id/edit
  def edit
  end

  # PATCH/PUT /admin/document_templates/:id
  def update
    if @document_template.update(document_template_params)
      # Re-extract variables if content changed
      if @document_template.saved_change_to_content? && @document_template.prawn_template?
        @document_template.update_variables_schema!
      end

      redirect_to admin_document_template_path(@document_template), notice: "Document template successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/document_templates/:id
  def destroy
    @document_template.destroy!
    redirect_to admin_document_templates_path, notice: "Document template successfully deleted."
  end

  # GET /admin/document_templates/:id/download
  def download
    if @document_template.pdf_file.attached?
      redirect_to rails_blob_path(@document_template.pdf_file, disposition: "attachment")
    else
      redirect_to admin_document_template_path(@document_template), alert: "No PDF file attached to this template."
    end
  end

  # GET /admin/document_templates/:id/preview
  def preview
    if @document_template.pdf_file.attached?
      redirect_to rails_blob_path(@document_template.pdf_file, disposition: "inline")
    else
      redirect_to admin_document_template_path(@document_template), alert: "No PDF file attached to preview."
    end
  end

  # GET /admin/document_templates/:id/generate
  def new_generate
    # Reuse the generate form template
    render :generate
  end

  # POST /admin/document_templates/:id/generate
  def generate
    variable_values = params[:variables] || {}
    action_type = params[:mode].presence || "download" # "preview" or "download"

    begin
      pdf_data = @document_template.generate_pdf(variable_values)

      if pdf_data
        filename = params[:filename].present? ? "#{params[:filename].parameterize}.pdf" : "#{@document_template.name.parameterize}-#{Date.current}.pdf"
        disposition = action_type == "preview" ? "inline" : "attachment"

        send_data pdf_data,
                  filename: filename,
                  type: "application/pdf",
                  disposition: disposition
      else
        redirect_to new_generate_admin_document_template_path(@document_template),
                    alert: "Unable to generate PDF from this template."
      end
    rescue => e
      redirect_to new_generate_admin_document_template_path(@document_template),
                  alert: "Error generating PDF: #{e.message}"
    end
  end

  private

  def set_document_template
    @document_template = DocumentTemplate.find(params[:id])
  end

  def document_template_params
    params.require(:document_template).permit(
      :name,
      :description,
      :template_type,
      :category,
      :content,
      :active,
      :pdf_file,
      variables: {}
    )
  end
end
