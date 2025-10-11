class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role-based access control
  enum :role, {
    viewer: "viewer",
    manager: "manager",
    admin: "admin"
  }, prefix: true

  # Validations
  validates :role, presence: true, inclusion: { in: roles.keys }

  # Role helper methods
  def admin?
    role == "admin"
  end

  def manager?
    role == "manager" || admin?
  end

  def viewer?
    role == "viewer"
  end
end
