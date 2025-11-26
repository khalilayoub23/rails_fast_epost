class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  OMNIAUTH_PROVIDERS = begin
    providers = %i[google_oauth2 facebook]
    providers << :developer if Rails.env.test?
    providers.freeze
  end

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :omniauthable, omniauth_providers: OMNIAUTH_PROVIDERS

  has_many :carrier_memberships, dependent: :destroy
  has_many :carriers, through: :carrier_memberships

  # Role-based access control
  enum :role, {
    viewer: "viewer",
    manager: "manager",
    operations_manager: "operations_manager",
    admin: "admin"
  }, prefix: true

  # Validations
  validates :role, presence: true, inclusion: { in: roles.keys }

  # Locate or create a user record for OmniAuth callback data
  def self.from_omniauth(auth)
    return nil unless auth&.provider.present? && auth&.uid.present?

    user = find_by(provider: auth.provider, uid: auth.uid)
    user ||= find_by(email: auth.info&.email)

    user ||= new(email: auth.info&.email.presence || default_email_for(auth))

    user.provider = auth.provider
    user.uid = auth.uid
    user.role ||= "viewer"
    user.password = Devise.friendly_token.first(20) if user.encrypted_password.blank?
    user.save(validate: user.email.present?)
    user
  end

  # Role helper methods
  def admin?
    role == "admin"
  end

  def manager?
    admin? || role.in?([ "manager", "operations_manager" ])
  end

  def operations_manager?
    role == "operations_manager" || admin?
  end

  def viewer?
    role == "viewer"
  end

  private_class_method def self.default_email_for(auth)
    return unless auth&.uid.present?

    "change-me-#{auth.provider}-#{auth.uid}@example.com"
  end

  private

  def password_required?
    return false if provider.present?

    super
  end
end
