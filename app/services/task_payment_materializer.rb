class TaskPaymentMaterializer
  class MissingSnapshotError < StandardError; end

  SNAPSHOT_TIME_FIELDS = %w[delivery_time requested_pickup_time].freeze

  def initialize(payment:)
    @payment = payment
  end

  def call
    return ensure_published_task(@payment.task) if @payment.task.present?

    if (task_id = @payment.metadata["task_id"].presence)
      return attach_to_existing_task(task_id)
    end

    snapshot = @payment.metadata.fetch("task_snapshot", nil)
    raise MissingSnapshotError, "task_snapshot missing" if snapshot.blank?

    create_task_from_snapshot(snapshot)
  end

  private

  def attach_to_existing_task(task_id)
    Task.transaction do
      task = Task.find(task_id)
      task.publish! unless task.published?
      @payment.update!(task: task)
      task
    end
  end

  def create_task_from_snapshot(snapshot)
    Task.transaction do
      task = Task.new(normalize_snapshot(snapshot))
      task.save!
      task.publish!
      @payment.update!(task: task)
      task
    end
  end

  def ensure_published_task(task)
    return task if task.nil?

    task.publish! unless task.published?
    task
  end

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
