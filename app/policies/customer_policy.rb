class CustomerPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user.present? && (admin? || manager? || support_agent? || warehouse_agent? || sender_like?)
  end

  def update?
    create?
  end

  def destroy?
    user.present? && (admin? || manager?)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.all
    end
  end

  private

  def sender_like?
    user.sender_role? || user.lawyer? || user.ecommerce_seller?
  end
end
