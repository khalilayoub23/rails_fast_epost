class UserPolicy < ApplicationPolicy
  def update_signature?
    user.present? && (user == record || manager?)
  end
end
