class PaymentPolicy < ApplicationPolicy
  def index?
    user.present? && (admin? || manager? || sender_role?)
  end

  def show?
    return false unless user

    return true if admin? || manager?
    sender_owns_payment?
  end

  def create?
    user.present? && (admin? || manager?)
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.admin? || user.manager?

      if sender_role?
        scope.left_outer_joins(:task).where(tasks: { sender_id: user.id })
      else
        scope.none
      end
    end

    private

    def sender_role?
      user.user_type_sender? || user.user_type_ecommerce_seller? || user.user_type_lawyer?
    end
  end

  private

  def sender_role?
    user.user_type_sender? || user.user_type_ecommerce_seller? || user.user_type_lawyer?
  end

  def sender_owns_payment?
    return false unless sender_role?

    task = record.task
    task.present? && task.sender_id == user.id
  end
end
