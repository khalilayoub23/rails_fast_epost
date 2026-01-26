class FormTemplatePolicy < ApplicationPolicy
  def index?
    admin? || manager?
  end

  def show?
    admin? || manager?
  end

  def create?
    admin? || manager?
  end

  def update?
    admin? || manager?
  end

  def destroy?
    admin? || manager?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.admin? || user.manager?

      scope.none
    end
  end
end
