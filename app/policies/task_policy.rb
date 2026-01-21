class TaskPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user

    admin? || manager? || support_agent? || warehouse_agent? || sender_owner? || carrier_member? || lawyer_assigned?
  end

  def create?
    return false unless user

    admin? || manager? || sender_role?
  end

  def update?
    return false unless user

    return true if admin? || manager?
    return true if warehouse_agent?
    return true if lawyer_assigned?
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
      elsif user.lawyer?
        # Lawyers can see tasks assigned to their Lawyer profile.
        lawyer_id = Lawyer.find_by(email: user.email)&.id
        lawyer_id ? scope.where(lawyer_id: lawyer_id) : scope.none
      else
        # Senders and ecommerce sellers see their own tasks
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

  def lawyer_assigned?
    return false unless user.lawyer? && record.respond_to?(:lawyer_id) && record.lawyer_id.present?

    lawyer_id = @lawyer_id ||= Lawyer.find_by(email: user.email)&.id
    lawyer_id.present? && record.lawyer_id == lawyer_id
  end

  def sender_role?
    user.sender_role? || user.lawyer? || user.ecommerce_seller?
  end
end
