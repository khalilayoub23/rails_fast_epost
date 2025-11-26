class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  layout "public"

  def home
    @stats = {
      total_deliveries: Task.delivered.count,
      active_shipments: Task.in_transit.count + Task.pending.count,
      total_customers: Customer.count,
      carriers_network: Carrier.count
    }
  end

  def about
  end

  def services
  end

  def contact
    @contact = ContactInquiry.new

    return unless request.post?

    @contact.assign_attributes(contact_inquiry_params)

    if @contact.save
      flash[:notice] = "Thank you! We'll get back to you within 24 hours."
      redirect_to pages_contact_path
    else
      flash.now[:alert] = "Please fix the errors below."
      render :contact, status: :unprocessable_entity
    end
  end

  def track_parcel
    if params[:tracking_number].present?
      @task = Task.find_by(barcode: params[:tracking_number].upcase.strip)
      if @task.nil?
        flash.now[:alert] = "Tracking number not found. Please check and try again."
      else
        @timeline_entries = build_timeline_entries(@task)
        @current_timeline_key = timeline_step_for(@task)
        @failed_attempt_history = failed_attempt_history(@task)
      end
    end
  end

  def law_firms
  end

  def ecommerce
  end

  def privacy_policy
  end

  def logo_test
    render layout: "logo_test"
  end

  def logo_demo
    render layout: "logo_test"
  end

  private

  def contact_inquiry_params
    params.require(:contact_inquiry).permit(:name, :email, :phone, :service, :message)
  end

  def build_timeline_entries(task)
    steps = default_timeline_entries(task)
              .index_by { |entry| entry[:key] }

    event_entries = []

    task.tracking_events.each do |event|
      entry = timeline_entry_from_event(event)
      next if entry.nil?

      if steps.key?(entry[:key])
        steps[entry[:key]] = entry
      else
        event_entries << entry
      end
    end

    combined_entries = steps.values + event_entries

    combined_entries.sort_by do |entry|
      weight = entry[:sort_weight] || STEP_ORDER.fetch(entry[:key], STEP_ORDER.length + 1)
      time_value = entry[:occurred_at]&.to_f || Float::INFINITY
      [weight, time_value]
    end
  end

  def default_timeline_entries(task)
    base_steps = [
      build_step(:order_created,
                 label: "Order Created",
                 desc: "Shipment registered in system",
                 icon: "package",
                 occurred_at: task.created_at,
                 actual_status: "pending"),
      build_step(:package_picked_up,
                 label: "Package Picked Up",
                 desc: "Courier collected the parcel",
                 icon: "delivery",
                 occurred_at: task.updated_at,
                 actual_status: "in_transit"),
      build_step(:out_for_delivery,
                 label: "Out for Delivery",
                 desc: "Messenger departed towards destination",
                 icon: "truck",
                 occurred_at: task.updated_at,
                 actual_status: "in_transit"),
      build_step(:delivered,
                 label: "Delivered",
                 desc: "Package delivered",
                 icon: "check",
                 occurred_at: task.delivery_time,
                 actual_status: "delivered")
    ]

    if task.failed_attempts.positive? || task.failed? || task.returned?
      base_steps << build_step(:failed,
                               label: "Delivery Failed",
                               desc: failure_step_description(task),
                               icon: "warning",
                               occurred_at: task.updated_at,
                               actual_status: "failed")
    end

    if task.returned?
      base_steps << build_step(:returned,
                               label: "Returned to Sender",
                               desc: return_step_description(task),
                               icon: "return",
                               occurred_at: task.updated_at,
                               actual_status: "returned")
    end

    base_steps
  end

  def build_step(key, label:, desc:, icon:, occurred_at:, actual_status:)
    {
      key: key,
      label: label,
      desc: desc,
      icon: icon,
      occurred_at: occurred_at,
      actual_status: actual_status
    }
  end

  def timeline_entry_from_event(event)
    case event.event_type
    when "failed"
      failed_attempt_entry(event)
    when "returned"
      build_event_entry(
        key: :returned,
        label: "Returned to Sender",
        desc: event.description_text.presence || "Package returning to origin",
        icon: "return",
        occurred_at: event.occurred_at,
        actual_status: event.status.presence || "returned"
      )
    else
      build_event_entry(
        key: event_step_key(event.event_type) || "event_#{event.id}".to_sym,
        label: event.title.presence || event.event_type.to_s.humanize,
        desc: event.description_text,
        icon: event.icon_name || "truck",
        occurred_at: event.occurred_at,
        actual_status: event.status.presence || event.event_type
      )
    end
  end

  STEP_ORDER = {
    order_created: 0,
    package_picked_up: 1,
    out_for_delivery: 2,
    failed: 3,
    delivered: 4,
    returned: 5
  }.freeze

  EVENT_STEP_MAP = {
    "created" => :order_created,
    "picked_up" => :package_picked_up,
    "out_for_delivery" => :out_for_delivery,
    "delivered" => :delivered,
    "returned" => :returned
  }.freeze

  def event_step_key(event_type)
    EVENT_STEP_MAP[event_type.to_s]
  end

  def timeline_step_for(task)
    case task.status
    when "pending"
      :order_created
    when "in_transit"
      :out_for_delivery
    when "delivered"
      :delivered
    when "failed"
      :failed
    when "returned"
      :returned
    else
      :order_created
    end
  end

  def failure_step_description(task)
    parts = []
    parts << task.last_failure_note if task.last_failure_note.present?
    if task.awaiting_customer_response? && task.stored_until.present?
      parts << "Parcel stored until #{task.stored_until.strftime('%b %d, %Y %I:%M %p %Z')} awaiting customer response"
    elsif task.failed_attempts > Task::MAX_FAILED_ATTEMPTS
      parts << "Exceeded #{Task::MAX_FAILED_ATTEMPTS} failed attempts"
    end
    parts << "Attempt #{[task.failed_attempts, Task::MAX_FAILED_ATTEMPTS].min} of #{Task::MAX_FAILED_ATTEMPTS}" if task.failed_attempts.positive?
    description = parts.compact.join(' | ')
    description.presence || "Delivery attempt unsuccessful"
  end

  def return_step_description(task)
    return "Package returning to origin" unless task.last_failure_note.present?
    "Returned after repeated failures: #{task.last_failure_note}"
  end

  def failed_attempt_entry(event)
    attempt_number = extract_attempt_number(event)
    key = "failed_attempt_#{attempt_number || event.id}".to_sym
    desc_parts = [event.description_text]

    stored_until = parse_stored_until(event.metadata)
    if stored_until.present?
      desc_parts << "Stored until #{stored_until.strftime('%b %d, %Y %I:%M %p %Z')}"
    end

    build_event_entry(
      key: key,
      label: attempt_number ? "Failed Attempt ##{attempt_number}" : "Delivery Attempt Failed",
      desc: desc_parts.compact.join(' | ').presence || "Delivery attempt unsuccessful",
      icon: "warning",
      occurred_at: event.occurred_at,
      actual_status: "failed",
      sort_weight: failed_attempt_weight(attempt_number)
    )
  end

  def build_event_entry(key:, label:, desc:, icon:, occurred_at:, actual_status:, sort_weight: nil)
    {
      key: key,
      label: label,
      desc: desc,
      icon: icon,
      occurred_at: occurred_at,
      actual_status: actual_status,
      sort_weight: sort_weight
    }
  end

  def extract_attempt_number(event)
    metadata = event.metadata || {}
    metadata[:attempt_number] || metadata["attempt_number"]
  end

  def parse_stored_until(metadata)
    value = metadata&.[](:stored_until) || metadata&.[]("stored_until")
    case value
    when String
      Time.zone.parse(value)
    when Time, ActiveSupport::TimeWithZone
      value
    else
      nil
    end
  rescue ArgumentError
    nil
  end

  def failed_attempt_history(task)
    task.tracking_events
        .where(event_type: "failed")
        .order(:occurred_at)
        .map
        .with_index(1) do |event, idx|
          {
            attempt_number: extract_attempt_number(event) || idx,
            occurred_at: event.occurred_at,
            note: event.description_text.presence || "Delivery attempt unsuccessful"
          }
        end
  end

  def failed_attempt_weight(attempt_number)
    base = STEP_ORDER[:out_for_delivery]
    increment = (attempt_number || 1).to_f / 10.0
    base + increment
  end
end
