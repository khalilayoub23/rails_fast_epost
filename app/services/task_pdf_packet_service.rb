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
    generate_completion_pdf if completion_trigger?
  end

  private

  attr_reader :task, :trigger

  def payment
    @payment ||= task.payments.where(gateway_status: "succeeded").order(created_at: :desc).first
  end

  def generate_from_active_templates
    generated = false

    DocumentTemplate.active_templates.find_each do |template|
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

  def template_variables
    {
      task_barcode: task.barcode,
      task_priority: task.priority,
      task_status: task.status,
      delivery_start: task.start,
      delivery_target: task.target,
      customer_name: task.customer&.name,
      customer_address: task.customer&.address,
      carrier_name: task.carrier&.name,
      lawyer_name: task.lawyer&.name,
      lawyer_email: task.lawyer&.email,
      sender_name: task.sender&.name,
      principal_name: task.customer&.name,
      agent_name: task.lawyer&.name || task.carrier&.name,
      shipper_name: task.sender&.name || task.customer&.name,
      invoice_number: "INV-#{task.barcode}",
      payment_reference: payment_reference,
      payment_amount_cents: payment&.amount_cents,
      generated_at: Time.current.iso8601
    }.compact.transform_keys(&:to_s)
  end

  def payment_reference
    payment&.external_id || payment&.payment_intent_id || payment&.charge_id || payment&.id&.to_s
  end
end
