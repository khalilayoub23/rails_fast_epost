class DeliveryPolicy < ApplicationPolicy
  def index?
    manager? || user.present?
  end

  def show?
    manager? || participant?
  end

  def create?
    manager? || user&.user_type_sender? || user&.user_type_lawyer?
  end

  def update?
    manager?
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
      return scope.all if user&.manager?
      return scope.none unless user

      scope.where("sender_id = :id OR courier_id = :id OR recipient_id = :id", id: user.id)
    end
  end

  private

  def participant?
    return false unless user && record.respond_to?(:sender_id)

    [ record.sender_id, record.courier_id, record.recipient_id ].include?(user.id)
  end
end
