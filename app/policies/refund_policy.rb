class RefundPolicy < ApplicationPolicy
  def index?
    user.present? && (admin? || manager? || sender_role?)
  end

  def show?
    return false unless user

    return true if admin? || manager?
    sender_role? && payment_policy.show?
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

      payments_scope = PaymentPolicy::Scope.new(user, Payment).resolve
      scope.joins(:payment).merge(payments_scope)
    end
  end

  private

  def sender_role?
    user.user_type_sender? || user.user_type_ecommerce_seller? || user.user_type_lawyer?
  end

  def payment_policy
    @payment_policy ||= PaymentPolicy.new(user, record.payment)
  end
end
