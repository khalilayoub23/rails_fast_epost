module Integrations
  class HubspotService
    def self.process(payload, headers: {}, signature_valid: false)
      external_id = IdExtractor.extract(provider: "hubspot", payload: payload, headers: headers)
      event = BaseService.record_event(provider: "hubspot", headers: headers, body: payload, signature_valid: signature_valid, external_id: external_id)
      return true if event.status_processed?

      # Very simple mapping: if payload contains email/name/phone, upsert Customer; add Remark if note/message present
      customer = upsert_customer(payload)
      remark_content = find_note(payload)
      if customer && remark_content.present?
        # Create remark on last task or generic note taskless via IntegrationEvent? We'll attach to a task if available by barcode/task_id
        success, task = Integrations::EventMapper.map(provider: "hubspot", payload: payload, headers: headers)
        if success && task
          Remark.create!(task: task, remarkable: customer, content: remark_content)
        end
      end

      BaseService.mark_processed!(event, true)
      true
    rescue => e
      BaseService.mark_processed!(event, false)
      Rails.logger.error("HubspotService error: #{e.message}")
      false
    end

    def self.upsert_customer(payload)
      email = deep_find(payload, %w[email properties.email value])
      name  = deep_find(payload, %w[name properties.name value])
      phone = deep_find(payload, %w[phone properties.phone value])

      return nil if email.blank? && name.blank? && phone.blank?

      customer = Customer.where(email: email.presence).or(Customer.where(name: name.presence)).first
      customer ||= Customer.new
      customer.email = email if email.present?
      customer.name = name if name.present?
      if phone.present?
        # append phone into text field `phones` for now
        phones = customer.phones.to_s
        customer.phones = (phones.split("\n") + [ phone ]).uniq.reject(&:blank?).join("\n")
      end
      customer.save!
      customer
    end

    def self.find_note(payload)
      deep_find(payload, %w[note message comment text])
    end

    def self.deep_find(obj, keys)
      return nil if obj.nil?
      queue = [ obj ]
      while queue.any?
        current = queue.shift
        case current
        when Hash
          keys.each do |k|
            return current[k] if current.key?(k)
          end
          current.each_value { |v| queue << v }
        when Array
          current.each { |v| queue << v }
        end
      end
      nil
    end
  end
end
