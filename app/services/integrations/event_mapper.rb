module Integrations
  class EventMapper
    class << self
      # Maps an inbound payload to a domain change.
      # For now: find a Task by task_id or barcode and create a Remark on it.
      # Returns [ success(Boolean), object_or_nil ]
      def map(provider:, payload:, headers: {})
        task = locate_task(payload)
        return [ false, nil ] unless task

        content = extract_message(payload) || payload.to_json
        remark = task.remarks.create(task: task, remarkable: task, content: content)
        remark.persisted? ? [ true, remark ] : [ false, nil ]
      end

      private

  def locate_task(payload)
    # Try explicit keys first
    task_id = find_value(payload, [ "task_id", "taskId", "id" ], Integer)
        return Task.find_by(id: task_id) if task_id

    barcode = find_value(payload, [ "barcode", "tracking_code", "trackingCode", "code" ])
        return Task.find_by(barcode: barcode) if barcode

        nil
      end

      def extract_message(payload)
        # Common message-like keys
        find_value(payload, [ "message", "text", "body", "content", "notes" ])
      end

      def find_value(obj, keys, klass = nil)
        queue = [ obj ]
        while queue.any?
          current = queue.shift
          case current
          when Hash
            keys.each do |k|
              if current.key?(k)
                val = current[k]
                return val if klass.nil? || val.is_a?(klass)
              end
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
end
