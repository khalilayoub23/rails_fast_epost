class TaskPaymentMaterializer
  class MissingSnapshotError < StandardError; end

  SNAPSHOT_TIME_FIELDS = %w[delivery_time requested_pickup_time].freeze

  def initialize(payment:)
    @payment = payment
  end

  def call
    return @payment.task if @payment.task.present?

    snapshot = @payment.metadata.fetch("task_snapshot", nil)
    raise MissingSnapshotError, "task_snapshot missing" if snapshot.blank?

    Task.transaction do
      task = Task.new(normalize_snapshot(snapshot))
      task.save!
      @payment.update!(task: task)
      task
    end
  end

  private

  def normalize_snapshot(snapshot)
    attrs = snapshot.deep_dup
    attrs.delete("id")
    attrs.delete("created_at")
    attrs.delete("updated_at")
    attrs["barcode"] = nil

    SNAPSHOT_TIME_FIELDS.each do |field|
      next if attrs[field].blank?
      attrs[field] = parse_time(attrs[field])
    end

    %w[customer_id carrier_id sender_id messenger_id lawyer_id].each do |field|
      attrs[field] = attrs[field].presence&.to_i if attrs.key?(field)
    end

    %w[failure_code status].each do |enum_field|
      attrs[enum_field] = attrs[enum_field].presence&.to_i if attrs.key?(enum_field)
    end

    attrs
  end

  def parse_time(value)
    return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
