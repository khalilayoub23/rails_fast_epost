module Integrations
  class IdExtractor
    CANDIDATE_KEYS = [
      # Telegram / generic
      "update_id", "message_id", "callback_query_id",
      # Meta
      "mid", "id", "event_id",
      # TikTok and others
      "eventId", "msg_id", "msgId"
    ].freeze

    def self.extract(provider:, payload:, headers: {})
      # Prefer header IDs if present
      header_id = headers["X-Request-Id"].presence || headers["X-Event-Id"].presence
      return header_id if header_id.present?

      # Scan payload for common keys
      value = find_value(payload, CANDIDATE_KEYS)
      value.to_s.presence
    end

    def self.find_value(obj, keys)
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
