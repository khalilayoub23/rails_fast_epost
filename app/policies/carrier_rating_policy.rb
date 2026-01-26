class CarrierRatingPolicy < ApplicationPolicy
  def create?
    user.present? && task_policy.show?
  end

  private

  def task_policy
    @task_policy ||= TaskPolicy.new(user, record.task)
  end
end
