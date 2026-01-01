class ViewerPolicy < ApplicationPolicy
  def access_dashboard?
    viewer?
  end

  def view_payments?
    viewer?
  end

  def view_tasks?
    viewer?
  end

  class Scope < Scope
    def resolve
      return scope.none unless viewer?

      if scope.respond_to?(:column_names) && scope.column_names.include?("sender_id")
        scope.where(sender_id: user.id)
      else
        scope.all
      end
    end
  end
end
