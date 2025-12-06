class CarrierPayoutPolicy < ApplicationPolicy
  def index?
    user.present? && (admin? || manager? || carrier_staff?)
  end

  def show?
    return false unless user

    return true if admin? || manager?
    carrier_staff? && payout_for_member_carrier?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.admin? || user.manager?

      if user.carrier_staff?
        scope.where(carrier_id: user.carriers.select(:id))
      else
        scope.none
      end
    end
  end

  private

  def payout_for_member_carrier?
    return false unless carrier_staff?
    record.respond_to?(:carrier_id) && user.carriers.where(id: record.carrier_id).exists?
  end
end
