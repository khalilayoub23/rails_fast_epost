class TaskPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user

    admin? || manager? || support_agent? || warehouse_agent? || sender_owner? || carrier_member?
  end

  def create?
    return false unless user

    admin? || manager? || sender_role?
  end

  def update?
    return false unless user

    return true if admin? || manager?
    return true if warehouse_agent?
    sender_owner? && record.status_pending?
  end

  def destroy?
    user.present? && (admin? || manager?)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.admin? || user.manager? || user.support_agent? || user.warehouse_agent?

      if user.carrier_staff?
        carrier_ids = user.carriers.select(:id)
        scope.where(carrier_id: carrier_ids)
      else
        scope.where(sender_id: user.id)
      end
    end
  end

  private

  def sender_owner?
    record.respond_to?(:sender_id) && record.sender_id == user.id
  end

  def carrier_member?
    return false unless user.carrier_staff? && record.respond_to?(:carrier_id) && record.carrier_id.present?

    user.carriers.where(id: record.carrier_id).exists?
  end

  def sender_role?
    user.user_type_sender? || user.user_type_ecommerce_seller? || user.user_type_lawyer?
  end
end
