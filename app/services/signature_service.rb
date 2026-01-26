require "digest"
require "stringio"
require "hexapdf"

class SignatureService
  SIGNATURE_POSITIONS = {
    "sender" => [ 50, 100 ],
    "courier" => [ 250, 100 ],
    "recipient" => [ 450, 100 ]
  }.freeze

  SIGNATURE_LABELS = {
    "sender" => "Sender / שולח",
    "courier" => "Courier / שליח",
    "recipient" => "Recipient / מקבל"
  }.freeze

  SIGNATURE_DIMENSIONS = { width: 150, height: 50 }.freeze

  def initialize(delivery = nil)
    @delivery = delivery
  end

  def add_signature(role:, signed_by_user:, ip_address:, signature_file: nil)
    role = role.to_s
    validate_role!(role)
    validate_user_matches_role!(role, signed_by_user)
    ensure_signature_pending!(role)

    Delivery.transaction do
      signature_bytes = load_signature_bytes(role, signed_by_user, signature_file)
      signature_hash = Digest::SHA256.hexdigest(signature_bytes)

      attach_signature_copy(role, signature_bytes)
      update_signature_data(role, signed_by_user, signature_hash, ip_address)

      SignatureEvent.create!(
        delivery: delivery,
        user: signed_by_user,
        role: role,
        action: :signature_added,
        signature_hash: signature_hash,
        ip_address: ip_address,
        metadata: { source: "web" }
      )

      if defined?(DeliveryMailer)
        message = DeliveryMailer.signature_added_notification(delivery, role)
        message&.deliver_later
      end

      regenerate_pdf_with_signatures(signature_bytes_by_role: { role => signature_bytes })
      finalize_if_complete
    end
  end

  def regenerate_pdf_with_signatures(signature_bytes_by_role: nil)
    return unless delivery.base_pdf.attached?

    Tempfile.create([ "delivery-current", ".pdf" ]) do |base|
      base.binmode
      delivery.base_pdf.download { |chunk| base.write(chunk) }
      base.rewind

      document = HexaPDF::Document.open(base.path)
      page = document.pages.first || document.pages.add
      canvas = page.canvas(type: :overlay)

      Delivery::SIGNATURE_ROLES.each do |role|
        next unless delivery.signature_completed?(role)

        bytes = signature_bytes_for(role, signature_bytes_by_role)
        next unless bytes

        draw_signature(canvas, document, bytes, role)
      end

      add_watermark(document) if delivery.all_required_signatures_completed?
      embed_attempt_metadata(document)

      Tempfile.create([ "delivery-current", ".pdf" ]) do |output|
        document.write(output.path, optimize: true)
        output.rewind
        attach_current_pdf(output)
        delivery.audit_logs.create!(action: "pdf_regenerated", user: delivery.sender, metadata: { role: "system" })
      end
    end
  end

  def finalize_if_complete
    return unless delivery.all_required_signatures_completed?

    copy_current_to_final
    delivery.update!(status: :completed, completed_at: Time.current)

    SignatureEvent.create!(
      delivery: delivery,
      user: delivery.sender,
      role: "system",
      action: :delivery_completed,
      metadata: { status: delivery.status }
    )

    persist_recipient_signature
    if defined?(DeliveryMailer)
      message = DeliveryMailer.delivery_completed(delivery)
      message&.deliver_later
    end

    notify_whatsapp_completion
  end

  def save_user_signature(user:, signature_file:)
    raise ArgumentError, "Signature file required" if signature_file.blank?
    unless user.user_type_lawyer? || user.user_type_courier?
      raise Pundit::NotAuthorizedError, "Only couriers and lawyers can store saved signatures"
    end

    user.saved_signature.attach(signature_file)
  end

  def save_recipient_signature_after_delivery(signature_file:)
    delivery.recipient.saved_signature.attach(signature_file)
  end

  private

  attr_reader :delivery

  def validate_role!(role)
    return if Delivery::SIGNATURE_ROLES.include?(role)

    raise ArgumentError, "Unknown signature role: #{role}"
  end

  def validate_user_matches_role?(role, user)
    delivery.public_send(role) == user
  end

  def validate_user_matches_role!(role, user)
    return if validate_user_matches_role?(role, user)

    raise Pundit::NotAuthorizedError, "User cannot sign for #{role}"
  end

  def ensure_signature_pending!(role)
    raise StandardError, "Signature already captured for #{role}" if delivery.signature_completed?(role)
  end

  def load_signature_bytes(role, user, signature_file)
    if role == "recipient"
      raise ArgumentError, "Signature data is required for recipient" if signature_file.blank?
      read_binary(signature_file)
    else
      raise ArgumentError, "Saved signature missing" unless user.has_saved_signature?
      user.saved_signature.download
    end
  end

  def attach_signature_copy(role, bytes)
    attachment = signature_attachment_for(role)
    attachment.attach(
      io: StringIO.new(bytes),
      filename: "#{role}-signature-#{Time.current.to_i}.png",
      content_type: "image/png"
    )
  end

  def signature_attachment_for(role)
    delivery.public_send("#{role}_signature_copy")
  end

  def signature_bytes_for(role, signature_bytes_by_role = nil)
    return signature_bytes_by_role[role] if signature_bytes_by_role&.key?(role)

    attachment = signature_attachment_for(role)
    if attachment&.attached?
      begin
        return attachment.download
      rescue ActiveStorage::FileNotFoundError
        # fall through to saved signatures
      end
    end

    if role != "recipient"
      user = delivery.public_send(role)
      return user.saved_signature.download if user&.has_saved_signature?
    end

    return delivery.recipient.saved_signature.download if role == "recipient" && delivery.recipient&.has_saved_signature?

    nil
  end

  def update_signature_data(role, user, signature_hash, ip_address)
    key = role.to_s
    payload = delivery.signature_snapshot
    data = payload[key] || {}

    data["required"] = true
    data["signed"] = true
    data["signed_at"] = Time.current.iso8601
    data["signed_by_user_id"] = user.id
    data["signature_hash"] = signature_hash
    data["ip_address"] = ip_address

    payload[key] = data
    delivery.send(:signature_data=, payload)
    delivery.status = delivery.all_required_signatures_completed? ? :fully_signed : :partially_signed
    delivery.audit_logs.create!(action: "signature_added", user: user, role: role, metadata: data)
    delivery.save!
  end

  def draw_signature(canvas, document, bytes, role)
    image = document.images.add(StringIO.new(bytes))
    position = SIGNATURE_POSITIONS[role]

    canvas.image(
      image,
      at: position,
      width: SIGNATURE_DIMENSIONS[:width],
      height: SIGNATURE_DIMENSIONS[:height]
    )

    label_position = [ position.first, position.last + SIGNATURE_DIMENSIONS[:height] + 15 ]
    timestamp_position = [ position.first, position.last - 15 ]

    canvas.font("Helvetica", size: 10)
    label_text = SIGNATURE_LABELS[role].encode("ASCII", invalid: :replace, undef: :replace, replace: "")
    canvas.text(label_text, at: label_position)

    data = delivery.signature_data[role.to_s]
    timestamp_text = "LOCK #{data["signed_at"]} ##{data["signed_by_user_id"]}"
    canvas.text(timestamp_text, at: timestamp_position)
  end

  def add_watermark(document)
    document.pages.each do |page|
      canvas = page.canvas(type: :overlay)
      canvas.save_graphics_state
      canvas.fill_color(0.82, 0.84, 0.86)
      canvas.opacity(fill_alpha: 0.1)
      canvas.translate(page.box.width / 2, page.box.height / 2)
      canvas.rotate(45)
      canvas.font_size(72)
      canvas.text("SIGNED", at: [ -150, 0 ])
      canvas.restore_graphics_state
    end
  end

  def embed_attempt_metadata(document)
    return unless delivery.respond_to?(:tracking_events)

    attempts = delivery.tracking_events.where(event_type: "failed").order(:occurred_at).limit(5)
    return if attempts.empty?

    page = document.pages.first || document.pages.add
    canvas = page.canvas(type: :overlay)
    canvas.font("Helvetica", size: 8)
    canvas.fill_color("#555555")

    attempts.each_with_index do |attempt, idx|
      y = page.box.top - 80 - (idx * 12)
      meta = attempt.metadata || {}
      location = meta["location"] || {}
      text = [
        "Attempt ##{meta["attempt_number"] || idx + 1}",
        attempt.occurred_at&.iso8601,
        (location.present? ? "(#{location["lat"]}, #{location["lng"]})" : nil)
      ].compact.join(" ")
      canvas.text(text, at: [ 50, y ])
    end
  end

  def attach_current_pdf(file)
    io = StringIO.new(File.binread(file.path))
    delivery.current_pdf.attach(
      io: io,
      filename: "delivery-#{delivery.id || "new"}-current-#{Time.current.to_i}.pdf",
      content_type: "application/pdf"
    )
  end

  def copy_current_to_final
    return unless delivery.current_pdf.attached?

    delivery.final_pdf.attach(delivery.current_pdf.blob)
  end

  def persist_recipient_signature
    return if delivery.recipient.has_saved_signature?
    return unless delivery.recipient_signature_copy.attached?

    delivery.recipient.saved_signature.attach(delivery.recipient_signature_copy.blob)
  end

  def notify_whatsapp_completion
    lawyer = delivery.sender
    return unless lawyer&.respond_to?(:phone)

    message = "Delivery #{delivery.case_number} completed"
    WhatsappNotifier.notify(number: lawyer.phone, message: message)
  end

  def read_binary(file)
    if file.respond_to?(:read)
      file.rewind if file.respond_to?(:rewind)
      data = file.read
      file.rewind if file.respond_to?(:rewind)
      data
    else
      file.to_s
    end
  end
end
