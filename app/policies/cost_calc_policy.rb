class CostCalcPolicy < ApplicationPolicy
  def index?
    task_policy.show?
  end

  def show?
    task_policy.show?
  end

  def create?
    task_policy.update?
  end

  def update?
    task_policy.update?
  end

  def destroy?
    task_policy.update?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.all
    end
  end

  private

  def task_policy
    @task_policy ||= TaskPolicy.new(user, record.task)
  end
end
