class TaskPdfPacketJob < ApplicationJob
  queue_as :default

  def perform(task_id:, trigger:, payment_id: nil)
    task = Task.find_by(id: task_id)
    return unless task

    payment = payment_id.present? ? Payment.find_by(id: payment_id) : nil
    TaskPdfPacketService.call(task: task, trigger: trigger, payment: payment)
  rescue => e
    Rails.logger.error("[TaskPdfPacketJob] task_id=#{task_id} trigger=#{trigger} payment_id=#{payment_id} failed: #{e.message}")
    raise
  end
end
