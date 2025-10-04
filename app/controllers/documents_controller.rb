class DocumentsController < ApplicationController
  before_action :set_carrier
  before_action :set_document, only: %i[show edit update destroy]

  def index
    @documents = @carrier.documents
    respond_to do |format|
      format.html
      format.json { render json: @documents }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @document }
    end
  end

  def new
    @document = @carrier.documents.new
  end

  def create
    @document = @carrier.documents.new(document_params)
    if @document.save
      respond_to do |format|
        format.html { redirect_to [ @carrier, @document ], notice: "Document created." }
        format.json { render json: @document, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @document.update(document_params)
      respond_to do |format|
        format.html { redirect_to [ @carrier, @document ], notice: "Document updated." }
        format.json { render json: @document }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @document.destroy
    respond_to do |format|
      format.html { redirect_to carrier_documents_path(@carrier), notice: "Document deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_carrier
    @carrier = Carrier.find(params[:carrier_id])
  end

  def set_document
    @document = @carrier.documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:id_document, :signature)
  end
end
