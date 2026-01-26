class FormPolicy < ApplicationPolicy
  def index?
    customer_policy.show?
  end

  def show?
    customer_policy.show?
  end

  def create?
    customer_policy.create?
  end

  def update?
    customer_policy.update?
  end

  def destroy?
    customer_policy.destroy?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.all
    end
  end

  private

  def customer_policy
    @customer_policy ||= CustomerPolicy.new(user, record.customer)
  end
end
