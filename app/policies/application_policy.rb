class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def admin?
    user&.admin?
  end

  def manager?
    user&.manager?
  end

  def support_agent?
    user&.support_agent?
  end

  def warehouse_agent?
    user&.warehouse_agent?
  end

  def carrier_staff?
    user&.carrier_staff?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end
  end
end
