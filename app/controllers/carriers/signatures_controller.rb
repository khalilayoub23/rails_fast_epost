module Carriers
  class SignaturesController < ApplicationController
    before_action :set_carrier

    def new
      @signature = signature_document
    end

    def edit
      @signature = signature_document
    end

    def create
      @signature = signature_document
      if @signature.update(signature_attributes)
        redirect_to carrier_path(@carrier), notice: "Carrier signature saved."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @signature = signature_document
      if @signature.update(signature_attributes)
        redirect_to carrier_path(@carrier), notice: "Carrier signature updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_carrier
      @carrier = Carrier.find(params[:carrier_id])
    end

    def signature_document
      @signature_document ||= @carrier.documents.find_or_initialize_by(id_document: Document::CARRIER_SIGNATURE_ID)
    end

    def signature_attributes
      signature_params.merge(id_document: Document::CARRIER_SIGNATURE_ID)
    end

    def signature_params
      params.require(:document).permit(:signature)
    end
  end
end
