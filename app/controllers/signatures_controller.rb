require "base64"
require "stringio"

class SignaturesController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_delivery
  before_action :set_role

  def new
    authorize @delivery, :sign?
    ensure_user_matches_role!
  end

  def create
    authorize @delivery, :sign?
    ensure_user_matches_role!

    signature_file = signature_io_for_role
    SignatureService.new(@delivery).add_signature(
      role: @role,
      signed_by_user: current_user,
      ip_address: request.remote_ip,
      signature_file: signature_file
    )
    @delivery.reload
    success_message = t("signatures.created", default: "Signature captured successfully.")

    respond_to do |format|
      format.html { redirect_to @delivery, notice: success_message }
      format.json do
        render json: {
          success: true,
          message: success_message,
          progress: @delivery.signature_progress,
          completed: @delivery.all_required_signatures_completed?
        }
      end
      format.turbo_stream { render_signature_success_stream(success_message) }
    end
  rescue Pundit::NotAuthorizedError => e
    raise e
  rescue StandardError => e
    respond_to do |format|
      format.html do
        flash.now[:alert] = e.message
        render :new, status: :unprocessable_entity
      end
      format.json { render json: { success: false, message: e.message }, status: :unprocessable_entity }
      format.turbo_stream { render_signature_error_stream(e.message) }
    end
  end

  def verify
    authorize @delivery, :status?
    unless Delivery::SIGNATURE_ROLES.include?(@role)
      render json: { valid: false, message: t("signatures.invalid_role", default: "Unknown role") }, status: :bad_request
      return
    end
    valid = @delivery.verify_signature_integrity(@role)
    message_key = valid ? "signatures.integrity.valid" : "signatures.integrity.invalid"
    render json: {
      valid: valid,
      role: @role,
      message: t(message_key, default: valid ? "Signature hash matches" : "Signature hash mismatch")
    }
  end

  def status
    authorize @delivery, :status?
    render json: {
      progress: @delivery.signature_progress,
      timeline: @delivery.signature_timeline,
      pending: @delivery.pending_signatures
    }
  end

  private

  def set_delivery
    @delivery = Delivery.find(params[:delivery_id])
  end

  def set_role
    @role = (params[:role] || params[:signature_role]).to_s.downcase
  end

  def ensure_user_matches_role!
    unless Delivery::SIGNATURE_ROLES.include?(@role)
      raise ActionController::BadRequest, "Unknown signature role"
    end
    raise Pundit::NotAuthorizedError unless @delivery.public_send(@role) == current_user
    raise StandardError, t("signatures.already_signed", default: "Signature already recorded for this role") if @delivery.signature_completed?(@role)
  end

  def signature_io_for_role
    return nil unless @role == "recipient"

    data_uri = params[:signature_data]
    raise ArgumentError, t("signatures.missing_data", default: "Signature data missing") if data_uri.blank?

    encoded = data_uri.split(",").last
    decoded = Base64.decode64(encoded)
    io = StringIO.new(decoded)
    io.set_encoding(Encoding::BINARY) if io.respond_to?(:set_encoding)
    io
  end

  def render_signature_success_stream(message)
    render turbo_stream: [
      turbo_stream.replace(dom_id(@delivery, :progress), partial: "deliveries/progress", locals: { delivery: @delivery }),
      turbo_stream.replace(dom_id(@delivery, :timeline), partial: "deliveries/timeline", locals: { delivery: @delivery }),
      turbo_stream.replace(dom_id(@delivery, "#{@role}_signature_card"), partial: "deliveries/signature_card", locals: { delivery: @delivery, role: @role }),
      turbo_stream.append("flash_messages", partial: "shared/flash_message", locals: { type: :notice, message: message })
    ]
  end

  def render_signature_error_stream(message)
    render turbo_stream: turbo_stream.append(
      "flash_messages",
      partial: "shared/flash_message",
      locals: { type: :alert, message: message }
    ), status: :unprocessable_entity
  end
end
