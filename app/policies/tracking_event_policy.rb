class TrackingEventPolicy < ApplicationPolicy
  def index?
    user.present? && (admin? || manager? || support_agent? || warehouse_agent? || carrier_staff?)
  end

  def show?
    index?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.admin? || user.manager? || user.support_agent? || user.warehouse_agent?

      if user.carrier_staff?
        scope.joins(:task).where(tasks: { carrier_id: user.carriers.select(:id) })
      else
        scope.none
      end
    end
  end
end
