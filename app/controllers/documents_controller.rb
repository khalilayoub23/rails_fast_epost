class DocumentsController < ApplicationController
  include Respondable

  before_action :set_carrier
  before_action :set_document, only: %i[show edit update destroy]

  def index
    authorize Document
    @documents = @carrier.documents
    respond_with_index(@documents)
  end

  def show
    authorize @document
    respond_with_show(@document)
  end

  def new
    @document = @carrier.documents.new
    authorize @document
  end

  def create
    @document = @carrier.documents.new(document_params)
    authorize @document
    respond_with_create(@document, @carrier, notice: "Document created.") do
      render turbo_stream: [
        turbo_stream.prepend("documents_list", partial: "documents/document_card", locals: { document: @document, carrier: @carrier }),
        turbo_stream.update("document_form", ""),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("documents.created") })
      ]
    end
  end

  def edit; end

  def update
    authorize @document
    respond_with_update(@document, @carrier, notice: "Document updated.", attributes: document_params) do
      render turbo_stream: [
        turbo_stream.replace(dom_id(@document), partial: "documents/document_card", locals: { document: @document, carrier: @carrier }),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("documents.updated") })
      ]
    end
  end

  def destroy
    authorize @document
    respond_with_destroy(@document, carrier_documents_path(@carrier), notice: "Document deleted.") do
      render turbo_stream: [
        turbo_stream.remove(dom_id(@document)),
        turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: t("documents.deleted") })
      ]
    end
  end

  private

  def set_carrier
    @carrier = Carrier.find(params[:carrier_id])
    authorize @carrier, :show?
  end

  def set_document
    @document = @carrier.documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:id_document, :signature)
  end
end
