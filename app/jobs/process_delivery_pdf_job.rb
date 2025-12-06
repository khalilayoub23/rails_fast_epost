class ProcessDeliveryPdfJob < ApplicationJob
  queue_as :pdf_processing

  def perform(delivery_id)
    delivery = Delivery.find(delivery_id)
    processor = PdfProcessorService.new(delivery)

    if delivery.original_court_pdf.attached?
      processor.add_system_barcode_to_court_pdf
    else
      processor.generate_delivery_form_with_barcode
    end

    AuthorizationPdfService.new(delivery).generate_and_attach

    delivery.update!(status: :awaiting_signatures)
    delivery.audit_logs.create!(action: "pdf_ready", user: delivery.sender)

    notify_signers(delivery)
    notify_lawyer(delivery)
  end

  private

  def notify_signers(delivery)
    %w[sender courier recipient].each do |role|
      user = delivery.public_send(role)
      message = DeliveryMailer.signature_request(delivery, user, role)
      message&.deliver_later
    end
  end

  def notify_lawyer(delivery)
    lawyer = delivery.try(:lawyer)
    return unless lawyer&.email.present?

    DeliveryMailer.delivery_completed(delivery)&.deliver_later if delivery.completed?
  end
end
