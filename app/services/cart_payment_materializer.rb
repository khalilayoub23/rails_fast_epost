class CartPaymentMaterializer
  def initialize(payment:)
    @payment = payment
  end

  def call
    tasks = tasks_from_payment

    Task.transaction do
      tasks.each do |task|
        task.publish!(validate: false) unless task.published?
        @payment.tasks << task unless @payment.tasks.exists?(task.id)
      end

      @payment.update!(task: tasks.first) if @payment.task_id.blank? && tasks.first
    end

    tasks
  end

  private

  def tasks_from_payment
    return @payment.tasks.to_a if @payment.tasks.loaded? ? @payment.tasks.any? : @payment.tasks.exists?

    ids = Array(@payment.metadata.to_h["task_ids"]).map(&:to_i)
    Task.where(id: ids)
  end
end
