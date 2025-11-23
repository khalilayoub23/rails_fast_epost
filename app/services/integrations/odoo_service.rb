module Integrations
  class OdooService
    # Process Odoo CRM webhooks (Free/Open Source version)
    # Supports: Contacts (res.partner), Leads (crm.lead), Opportunities
    def self.process(payload, headers: {})
      external_id = IdExtractor.extract(provider: "odoo", payload: payload, headers: headers)
      event = BaseService.record_event(
        provider: "odoo",
        headers: headers,
        body: payload,
        signature_valid: true, # API key already validated in controller
        external_id: external_id
      )
      return true if event.status_processed?

      # Determine Odoo model type
      model = payload["model"] || payload["object"]

      case model
      when "res.partner", "contact"
        process_contact(payload)
      when "crm.lead", "lead", "opportunity"
        process_lead(payload)
      else
        Rails.logger.info("[OdooService] Unknown model type: #{model}")
      end

      BaseService.mark_processed!(event, true)
      true
    rescue => e
      BaseService.mark_processed!(event, false)
      Rails.logger.error("[OdooService] Error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      false
    end

    # Process Odoo Contact (res.partner)
    def self.process_contact(payload)
      data = payload["data"] || payload

      email = extract_field(data, %w[email partner_email email_from])
      name = extract_field(data, %w[name display_name partner_name])
      phone = extract_field(data, %w[phone mobile partner_phone])
      address = extract_field(data, %w[street street2 contact_address])

      return nil if email.blank? && name.blank?

      # Find or create customer
      customer = Customer.find_or_initialize_by(email: email) if email.present?
      customer ||= Customer.find_or_initialize_by(name: name) if name.present?
      customer ||= Customer.new

      customer.email = email if email.present?
      customer.name = name if name.present?
      customer.address = address if address.present?

      # Handle phone numbers
      if phone.present?
        existing_phones = customer.phones.to_s.split("\n").map(&:strip).reject(&:blank?)
        customer.phones = (existing_phones + [ phone ]).uniq.join("\n")
      end

      customer.allow_partial_profile = true
      customer.category ||= :individual if customer.category.blank?

      customer.save!
      Rails.logger.info("[OdooService] Contact synced: #{customer.email || customer.name}")
      customer
    end

    # Process Odoo Lead/Opportunity (crm.lead)
    def self.process_lead(payload)
      data = payload["data"] || payload

      # Extract lead information
      name = extract_field(data, %w[name lead_name opportunity_name])
      email = extract_field(data, %w[email_from partner_email contact_email])
      phone = extract_field(data, %w[phone mobile contact_number])
      description = extract_field(data, %w[description notes note])
      stage = extract_field(data, %w[stage_id stage])

      # Create or update customer from lead
      customer = nil
      if email.present?
        customer = process_contact({
          "email" => email,
          "name" => name,
          "phone" => phone
        })
      end

      # Create remark if description exists and customer found
      if customer && description.present?
        # Try to find associated task from payload or create generic remark
        task = find_task_from_payload(data)

        if task
          Remark.create!(
            task: task,
            remarkable: customer,
            content: "[Odoo Lead] #{description}"
          )
          Rails.logger.info("[OdooService] Lead remark created for task ##{task.id}")
        else
          Rails.logger.info("[OdooService] Lead processed but no task found: #{name}")
        end
      end

      customer
    end

    # Extract field from nested hash/array structure
    def self.extract_field(data, field_names)
      return nil if data.nil?

      # Try direct keys first
      field_names.each do |key|
        return data[key] if data[key].present?
      end

      # Try nested search
      queue = [ data ]
      while queue.any?
        current = queue.shift
        case current
        when Hash
          field_names.each do |key|
            return current[key] if current.key?(key) && current[key].present?
          end
          current.each_value { |v| queue << v if v.is_a?(Hash) || v.is_a?(Array) }
        when Array
          current.each { |v| queue << v if v.is_a?(Hash) }
        end
      end
      nil
    end

    # Find task from payload (barcode, task_id, or reference)
    def self.find_task_from_payload(data)
      barcode = extract_field(data, %w[barcode tracking_number reference])
      task_id = extract_field(data, %w[task_id x_task_id])

      return Task.find_by(id: task_id) if task_id.present?
      return Task.find_by(barcode: barcode) if barcode.present?

      # Return most recent task for customer if no specific reference
      nil
    end
  end
end
