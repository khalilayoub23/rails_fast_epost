class LegalFormAutomationService
  include Rails.application.routes.url_helpers

  DEFAULT_SCHEMA = {
    "title" => "FastEpost Legal Packet",
    "fields" => [
      { "name" => "task_barcode", "label" => "Task Barcode", "type" => "text" },
      { "name" => "task_priority", "label" => "Priority", "type" => "text" },
      { "name" => "task_status", "label" => "Status", "type" => "text" },
      { "name" => "delivery_start", "label" => "Pickup Address", "type" => "text" },
      { "name" => "delivery_target", "label" => "Delivery Address", "type" => "text" },
      { "name" => "customer_name", "label" => "Customer Name", "type" => "text" },
      { "name" => "customer_address", "label" => "Customer Address", "type" => "text" },
      { "name" => "carrier_name", "label" => "Carrier", "type" => "text" },
      { "name" => "carrier_signature", "label" => "Carrier Signature", "type" => "signature" },
      { "name" => "carrier_signature_captured", "label" => "Signature On File", "type" => "text" },
      { "name" => "lawyer_name", "label" => "Assigned Lawyer", "type" => "text" },
      { "name" => "lawyer_email", "label" => "Lawyer Email", "type" => "text" },
      { "name" => "payment_reference", "label" => "Payment Reference", "type" => "text" },
      { "name" => "payment_amount_cents", "label" => "Payment Amount (cents)", "type" => "number" },
      { "name" => "generated_at", "label" => "Generated At", "type" => "text" }
    ]
  }.freeze

  def self.call(task:, payment: nil)
    new(task: task, payment: payment).call
  end

  def initialize(task:, payment: nil)
    @task = task
    @payment = payment
  end

  def call
    return unless task&.customer && task&.carrier && task&.lawyer

    template = ensure_template!
    form = task.forms.find_or_initialize_by(form_template: template)
    form.customer = task.customer
    form.task = task
    form.address = task.target.presence || task.customer.address
    form.form_default_url ||= template_default_url(template)
    payload = default_payload
    form.data = (form.data || {}).merge(payload)
    form.save!
    form
  end

  private

  attr_reader :task, :payment

  def ensure_template!
    template = FormTemplate.find_or_initialize_by(carrier: task.carrier, customer: task.customer)
    if template.new_record? || template.schema.blank?
      template.schema = DEFAULT_SCHEMA.deep_dup
    else
      template.schema["fields"] ||= []
      missing_fields = DEFAULT_SCHEMA["fields"].reject do |field|
        template.schema["fields"].any? { |existing| existing["name"] == field["name"] }
      end
      template.schema["fields"].concat(missing_fields) if missing_fields.any?
      template.schema["title"] ||= DEFAULT_SCHEMA["title"]
    end
    template.save! if template.changed?
    template
  end

  def template_default_url(template)
    base = base_url.chomp("/")
    path = form_template_path(template)
    "#{base}#{path}"
  end

  def base_url
    ENV["APP_BASE_URL"].presence || Rails.application.routes.default_url_options[:host].presence || "https://fast-epost.test"
  end

  def default_payload
    {
      "task_barcode" => task.barcode,
      "task_priority" => task.priority,
      "task_status" => task.status,
      "delivery_start" => task.start,
      "delivery_target" => task.target,
      "customer_name" => task.customer.name,
      "customer_address" => task.customer.address,
      "carrier_name" => task.carrier.name,
      "carrier_signature" => carrier_signature_value,
      "carrier_signature_captured" => carrier_signature_value.present?.to_s,
      "lawyer_name" => task.lawyer&.name,
      "lawyer_email" => task.lawyer&.email,
      "payment_reference" => payment_reference,
      "payment_amount_cents" => payment&.amount_cents,
      "generated_at" => Time.current.iso8601
    }.compact
  end

  def carrier_signature_value
    task.carrier.signature_document&.signature
  end

  def payment_reference
    payment&.external_id || payment&.payment_intent_id || payment&.charge_id || payment&.id&.to_s
  end
end
