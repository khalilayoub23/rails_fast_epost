class PaymentsTaskPolicy < ApplicationPolicy
  def create?
    admin? || manager?
  end

  def destroy?
    admin? || manager?
  end
end
