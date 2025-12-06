class DeliveryPolicy < ApplicationPolicy
  def index?
    manager? || user.present?
  end

  def show?
    manager? || support_agent? || warehouse_agent? || participant?
  end

  def create?
    manager? || user&.user_type_sender? || user&.user_type_lawyer? || user&.user_type_ecommerce_seller?
  end

  def update?
    manager? || warehouse_agent?
  end

  def destroy?
    admin?
  end

  def sign?
    participant?
  end

  def status?
    show?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.manager? || user.support_agent? || user.warehouse_agent?

      scope.where("sender_id = :id OR courier_id = :id OR recipient_id = :id", id: user.id)
    end
  end

  private

  def participant?
    return false unless user && record.respond_to?(:sender_id)

    [ record.sender_id, record.courier_id, record.recipient_id ].include?(user.id)
  end
end
