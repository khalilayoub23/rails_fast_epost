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

  def publish?
    return false unless user

    admin? || manager? || support_agent? || sender_owner? || lawyer_assigned?
  end

  def destroy?
    return false unless user.present?

    # Admins and managers can always destroy
    return true if admin? || manager?

    # Allow lawyers to delete tasks they created, but only when the task
    # is currently in their cart and not assigned to a carrier/messenger
    if user.lawyer?
      # ensure the task was created by this user
      return false unless record.created_by_id == user.id

      # if task is assigned to carrier/messenger or already in transit, disallow
      return false if record.messenger_id.present? || record.carrier_id.present? || record.status == "in_transit"

      # check cart membership without creating a cart unnecessarily
      cart = Cart.find_by(user: user)
      return false unless cart
      return cart.tasks.where(id: record.id).exists?
    end

    false
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
        lawyer_id = user.ensure_lawyer_profile!&.id
        lawyer_id ? scope.where(lawyer_id: lawyer_id) : scope.none
      else
        # Publicly published tasks should be visible to all users, plus any tasks
        # they created or own as a sender.
        scope.where(published: true).or(scope.where(sender_id: user.id).or(scope.where(created_by_id: user.id)))
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

    lawyer_id = @lawyer_id ||= user.ensure_lawyer_profile!&.id
    lawyer_id.present? && record.lawyer_id == lawyer_id
  end

  def sender_role?
    user.sender_role? || user.lawyer? || user.ecommerce_seller?
  end
end
