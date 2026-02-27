require "base64"
require "ostruct"

class TaskPdfPacketService
  def self.call(task:, trigger:, payment: nil)
    new(task: task, trigger: trigger, payment: payment).call
  end

  def initialize(task:, trigger:, payment: nil)
    @task = task
    @trigger = trigger.to_s
    @payment = payment
  end

  def call
    return unless task&.persisted?

    generated_any = generate_from_active_templates
    generate_summary_pdf unless generated_any
    generate_invoice_pdf if payment_trigger?
    generate_completion_pdf if completion_trigger?
  end

  private

  attr_reader :task, :trigger

  def payment
    @payment ||= task.payments.where(gateway_status: "succeeded").order(created_at: :desc).first
  end

  def generate_from_active_templates
    generated = false

    templates = preferred_active_templates

    templates.each do |template|
      next unless template.ready_for_use?

      pdf_binary = template.generate_pdf(template_variables)
      next if pdf_binary.blank?

      filename = "task-#{task.barcode}-#{trigger}-template-#{template.id}.pdf"
      attach_or_replace_legal_file(filename: filename, data: pdf_binary)
      generated = true
    rescue => e
      Rails.logger.error("[TaskPdfPacketService] Template #{template.id} failed for Task #{task.id}: #{e.message}")
    end

    generated
  end

  def preferred_active_templates
    templates = DocumentTemplate.active_templates.to_a

    preferred_legal_template = templates.find { |template| legal_delivery_form_2?(template) }
    return templates unless preferred_legal_template

    templates.reject { |template| legacy_legal_delivery_form?(template) }
  end

  def legal_delivery_form_2?(template)
    normalized_name = template.name.to_s.downcase
    normalized_name.include?("legal delivery conformation form 2") ||
      normalized_name.include?("legal delivery confirmation form 2")
  end

  def legacy_legal_delivery_form?(template)
    normalized_name = template.name.to_s.downcase
    return false unless normalized_name.include?("legal delivery conformation form") ||
      normalized_name.include?("legal delivery confirmation form")

    !normalized_name.include?("form 2")
  end

  def generate_summary_pdf
    title = "Task #{task.barcode} - #{trigger.humanize}"
    sections = [
      {
        heading: "Task Overview",
        body: [
          "Barcode: #{task.barcode}",
          "Status: #{task.status}",
          "Priority: #{task.priority}",
          "Task Type: #{task.task_type}",
          "Package Type: #{task.package_type}"
        ].join("\n")
      },
      {
        heading: "Route",
        body: [
          "Start: #{task.start}",
          "Target: #{task.target}",
          "Delivery Time: #{task.delivery_time}"
        ].join("\n")
      },
      {
        heading: "Participants",
        body: [
          "Customer: #{task.customer&.name}",
          "Carrier: #{task.carrier&.name}",
          "Sender: #{task.sender&.name}",
          "Messenger: #{task.messenger&.name}",
          "Lawyer: #{task.lawyer&.name}"
        ].join("\n")
      }
    ]

    summary_pdf = PdfGeneratorService.generate_simple_document(
      title,
      sections,
      date: Time.current.strftime("%B %d, %Y %H:%M"),
      include_signature: false
    )

    return if summary_pdf.blank?

    attach_or_replace_legal_file(
      filename: "task-#{task.barcode}-#{trigger}-summary.pdf",
      data: summary_pdf
    )
  end

  def generate_completion_pdf
    sections = [
      {
        heading: "Completion Certificate",
        body: [
          "Task #{task.barcode} has been completed successfully.",
          "Delivered At: #{Time.current}",
          "Carrier: #{task.carrier&.name}",
          "Customer: #{task.customer&.name}",
          "Target: #{task.target}"
        ].join("\n")
      }
    ]

    completion_pdf = PdfGeneratorService.generate_simple_document(
      "Task Completion Certificate",
      sections,
      date: Time.current.strftime("%B %d, %Y %H:%M"),
      include_signature: true
    )

    return if completion_pdf.blank?

    attach_or_replace_legal_file(
      filename: "task-#{task.barcode}-completion-certificate.pdf",
      data: completion_pdf
    )
  end

  def generate_invoice_pdf
    return unless payment.present?

    config = invoice_configuration
    invoice_number = "INV-#{task.barcode}-#{payment.id}"
    issue_timestamp = Time.current

    details_lines = [
      "Invoice Number: #{invoice_number}",
      "Issue Date: #{issue_timestamp.strftime('%Y-%m-%d %H:%M')}",
      "Payment Reference: #{payment_reference}",
      "Payment Status: #{payment.gateway_status}",
      "Payment Provider: #{payment.provider.to_s.upcase}",
      "Amount: #{formatted_invoice_amount}",
      "Payment Terms: #{config[:payment_terms]}"
    ]

    if config[:include_internal_ids]
      details_lines << "Task ID: #{task.id}"
      details_lines << "Payment ID: #{payment.id}"
    end

    from_lines = [ "Name: #{config[:issuer_name]}" ]
    from_lines << "Address: #{config[:issuer_address]}" if config[:issuer_address].present?
    from_lines << "Email: #{config[:issuer_email]}" if config[:issuer_email].present?
    from_lines << "Tax ID: #{config[:tax_id]}" if config[:tax_id].present?

    bill_to_lines = [ "Customer: #{task.customer&.name}" ]
    bill_to_lines << "Address: #{task.customer&.address}" if task.customer&.address.present?
    bill_to_lines << "Email: #{task.customer&.email}" if task.customer&.email.present?

    task_lines = [
      "Task Barcode: #{task.barcode}",
      "Task Type: #{task.task_type.to_s.humanize}",
      "Package Type: #{task.package_type}",
      "Route: #{task.start} -> #{task.target}",
      "Priority: #{task.priority}",
      "Sender: #{task.sender&.name}",
      "Carrier: #{task.carrier&.name}"
    ]

    line_item_description = task.task_type.to_s.humanize.presence || "Task Service"
    line_items_lines = [
      "1 x #{line_item_description}",
      "Unit Price: #{formatted_invoice_amount}",
      "Total: #{formatted_invoice_amount}"
    ]

    sections = [
      {
        heading: "Invoice Details",
        body: details_lines.join("\n")
      },
      {
        heading: "From",
        body: from_lines.join("\n")
      },
      {
        heading: "Bill To",
        body: bill_to_lines.join("\n")
      },
      {
        heading: "Service Details",
        body: task_lines.join("\n")
      },
      {
        heading: "Line Items",
        body: line_items_lines.join("\n")
      }
    ]

    if config[:support_email].present? || config[:footer_note].present?
      notes_lines = []
      notes_lines << "Support: #{config[:support_email]}" if config[:support_email].present?
      notes_lines << config[:footer_note] if config[:footer_note].present?
      sections << { heading: "Notes", body: notes_lines.join("\n") }
    end

    invoice_pdf = PdfGeneratorService.generate_simple_document(
      "Task Invoice",
      sections,
      date: issue_timestamp.strftime("%B %d, %Y %H:%M"),
      include_signature: false
    )

    return if invoice_pdf.blank?

    attach_or_replace_legal_file(
      filename: "task-#{task.barcode}-invoice-#{payment.id}.pdf",
      data: invoice_pdf
    )
  end

  def attach_or_replace_legal_file(filename:, data:)
    existing = task.legal_files.attachments.find { |attachment| attachment.filename.to_s == filename }
    existing&.purge

    task.legal_files.attach(
      io: StringIO.new(data),
      filename: filename,
      content_type: "application/pdf"
    )
  end

  def completion_trigger?
    trigger == "delivered"
  end

  def payment_trigger?
    trigger == "payment_succeeded"
  end

  def template_variables
    customer = task.customer
    sender = resolved_sender_profile
    carrier = task.carrier
    lawyer = resolved_lawyer_profile
    messenger = task.messenger

    {
      task_id: task.id,
      task_barcode: task.barcode,
      task_priority: task.priority,
      task_status: task.status,
      task_type: task.task_type,
      package_type: task.package_type,
      case_file_number: task.case_file_number,
      id_number: task.id_number,
      task_created_at: format_datetime(task.created_at),
      task_updated_at: format_datetime(task.updated_at),
      task_published_at: format_datetime(task.published_at),
      task_delivery_time: format_datetime(task.delivery_time),
      task_requested_pickup_time: format_datetime(task.requested_pickup_time),
      task_distance_km: task.distance,
      task_pickup_address: task.pickup_address,
      task_pickup_contact_phone: task.pickup_contact_phone,
      task_pickup_notes: task.pickup_notes,
      task_collection_amount: task.collection_amount,
      task_collection_currency: task.collection_currency,
      task_delivery_medium: task.delivery_medium,
      task_start: task.start,
      task_target: task.target,
      delivery_start: task.start,
      delivery_target: task.target,
      delivery_date: format_date(task.delivery_time),
      delivery_time: format_time(task.delivery_time),
      requested_pickup_date: format_date(task.requested_pickup_time),
      requested_pickup_time: format_time(task.requested_pickup_time),
      customer_name: customer&.name,
      customer_address: customer&.address,
      customer_email: customer&.email,
      customer_phone: primary_customer_phone(customer),
      customer_phones: all_customer_phones(customer),
      recipient_name: customer&.name,
      recipient_address: customer&.address,
      recipient_email: customer&.email,
      recipient_phone: primary_customer_phone(customer),
      carrier_name: carrier&.name,
      carrier_email: carrier&.email,
      carrier_address: carrier&.address,
      carrier_type: carrier&.carrier_type,
      sender_name: sender_name_value(sender, customer),
      sender_company_name: sender_company_value(sender),
      sender_email: sender_email_value(sender, customer),
      sender_address: sender_address_value(sender, customer),
      sender_phone: sender_phone_value(sender, customer),
      sender_secondary_phone: sender_secondary_phone_value(sender),
      sender_tax_id: sender_tax_id_value(sender),
      sender_business_registration: sender_business_registration_value(sender),
      lawyer_name: lawyer&.name,
      lawyer_address: lawyer_address_value(lawyer, customer),
      lawyer_email: lawyer&.email,
      lawyer_phone: lawyer&.phone,
      lawyer_license_number: lawyer&.license_number,
      messenger_name: messenger&.name,
      messenger_email: messenger&.email,
      messenger_phone: messenger&.phone,
      messenger_vehicle_type: messenger&.vehicle_type,
      principal_name: customer&.name,
      principal_address: customer&.address,
      principal_email: customer&.email,
      agent_name: lawyer&.name || carrier&.name,
      agent_address: lawyer_address_value(lawyer, customer) || carrier&.address,
      agent_email: lawyer&.email || carrier&.email,
      shipper_name: sender_name_value(sender, customer),
      shipper_address: sender_address_value(sender, customer),
      shipper_phone: sender_phone_value(sender, customer),
      carrier_signature: carrier_signature_data_url,
      sender_signature: sender_signature_data_url,
      recipient_signature: recipient_signature_data_url || sender_signature_data_url || carrier_signature_data_url,
      invoice_number: "INV-#{task.barcode}",
      payment_reference: payment_reference,
      payment_amount_cents: payment&.amount_cents,
      payment_amount: formatted_invoice_amount,
      payment_currency: payment&.currency,
      generated_at: Time.current.iso8601
    }.compact.transform_keys(&:to_s)
  end

  def carrier_signature_data_url
    signature = task.carrier&.signature_document&.signature.to_s
    return nil if signature.blank?

    return signature if signature.start_with?("data:image")

    "data:image/png;base64,#{signature}"
  end

  def sender_signature_data_url
    sender_user = User.find_by(email: task.sender&.email) if task.sender&.email.present?
    sender_user ||= task.created_by

    signature_data_url_for_user(sender_user)
  end

  def recipient_signature_data_url
    recipient_user = User.find_by(email: task.customer&.email) if task.customer&.email.present?
    signature_data_url_for_user(recipient_user)
  end

  def resolved_sender_profile
    return task.sender if task.sender.present?

    OpenStruct.new(
      name: task.created_by&.full_name.presence || task.created_by&.email&.split("@")&.first&.to_s&.titleize,
      email: task.created_by&.email,
      address: task.customer&.address,
      phone: primary_customer_phone(task.customer)
    )
  end

  def resolved_lawyer_profile
    return task.lawyer if task.lawyer.present?

    return nil unless task.created_by&.lawyer?

    OpenStruct.new(
      name: task.created_by&.full_name.presence || task.created_by&.email&.to_s,
      email: task.created_by&.email,
      address: nil,
      phone: nil,
      license_number: nil
    )
  end

  def lawyer_address_value(lawyer, customer)
    return nil unless lawyer&.respond_to?(:address)

    lawyer&.address
  end

  def sender_name_value(sender, customer)
    sender&.name.presence || sender&.company_name.presence || customer&.name
  end

  def sender_email_value(sender, customer)
    sender&.email.presence || customer&.email
  end

  def sender_address_value(sender, customer)
    sender&.address.presence || customer&.address
  end

  def sender_phone_value(sender, customer)
    sender&.phone.presence || primary_customer_phone(customer)
  end

  def sender_company_value(sender)
    sender.respond_to?(:company_name) ? sender&.company_name : nil
  end

  def sender_secondary_phone_value(sender)
    sender.respond_to?(:secondary_phone) ? sender&.secondary_phone : nil
  end

  def sender_tax_id_value(sender)
    sender.respond_to?(:tax_id) ? sender&.tax_id : nil
  end

  def sender_business_registration_value(sender)
    sender.respond_to?(:business_registration) ? sender&.business_registration : nil
  end

  def signature_data_url_for_user(user)
    return nil unless user&.saved_signature&.attached?

    mime_type = user.saved_signature.blob.content_type.presence || "image/png"
    encoded = Base64.strict_encode64(user.saved_signature.download)
    "data:#{mime_type};base64,#{encoded}"
  rescue => _e
    nil
  end

  def payment_reference
    payment&.external_id || payment&.payment_intent_id || payment&.charge_id || payment&.id&.to_s
  end

  def formatted_invoice_amount
    currency_code = payment&.currency.to_s.upcase.presence || ENV.fetch("DEFAULT_CURRENCY", "ILS")
    amount = payment&.amount_cents.to_i / 100.0
    format("%.2f %s", amount, currency_code)
  end

  def format_datetime(value)
    value&.strftime("%Y-%m-%d %H:%M")
  end

  def format_date(value)
    value&.strftime("%Y-%m-%d")
  end

  def format_time(value)
    value&.strftime("%H:%M")
  end

  def primary_customer_phone(customer)
    customer&.phones&.first
  end

  def all_customer_phones(customer)
    phones = Array(customer&.phones).compact
    phones.any? ? phones.join(", ") : nil
  end

  def invoice_configuration
    {
      issuer_name: ENV["INVOICE_ISSUER_NAME"].presence || task.carrier&.name || "Fast Epost",
      issuer_address: ENV["INVOICE_ISSUER_ADDRESS"].presence || task.carrier&.address,
      issuer_email: ENV["INVOICE_ISSUER_EMAIL"].presence || task.carrier&.email,
      tax_id: ENV["INVOICE_TAX_ID"].presence,
      support_email: ENV["INVOICE_SUPPORT_EMAIL"].presence,
      payment_terms: ENV["INVOICE_PAYMENT_TERMS"].presence || "Paid",
      footer_note: ENV["INVOICE_FOOTER_NOTE"].presence || "Locally generated invoice for task payment records.",
      include_internal_ids: ENV.fetch("INVOICE_INCLUDE_INTERNAL_IDS", "false") == "true"
    }
  end
end
