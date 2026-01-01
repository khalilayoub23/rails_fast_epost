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

  has_many :sent_deliveries, class_name: "Delivery", foreign_key: :sender_id, inverse_of: :sender
  has_many :received_deliveries, class_name: "Delivery", foreign_key: :recipient_id, inverse_of: :recipient
  has_many :courier_deliveries, class_name: "Delivery", foreign_key: :courier_id, inverse_of: :courier
  has_many :proof_uploads, foreign_key: :uploaded_by_id, dependent: :destroy

  has_one_attached :saved_signature

  # Role-based access control
  enum :role, {
    manager: "manager",
    operations_manager: "operations_manager",
    admin: "admin",
    support_agent: "support_agent",
    warehouse_agent: "warehouse_agent",
    carrier_staff: "carrier_staff",
    carrier: "carrier",
    sender: "sender",
    lawyer: "lawyer",
    ecommerce_seller: "ecommerce_seller"
  }, prefix: true

  enum :user_type, {
    sender: 0,
    lawyer: 1,
    courier: 2,
    recipient: 3,
    ecommerce_seller: 4
  }, prefix: true

  # Validations
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :user_type, presence: true

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= :sender
    self.user_type ||= :sender
  end

  # Locate or create a user record for OmniAuth callback data
  def self.from_omniauth(auth)
    return nil unless auth&.provider.present? && auth&.uid.present?

    user = find_by(provider: auth.provider, uid: auth.uid)
    user ||= find_by(email: auth.info&.email)

    user ||= new(email: auth.info&.email.presence || default_email_for(auth))

    user.provider = auth.provider
    user.uid = auth.uid
    user.role ||= "sender"
    user.user_type ||= :sender
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

  def carrier?
    role == "carrier"
  end

  def sender_role?
    role == "sender"
  end

  def support_agent?
    role == "support_agent"
  end

  def warehouse_agent?
    role == "warehouse_agent"
  end

  def carrier_staff?
    role.in?(%w[carrier_staff carrier])
  end

  def viewer?
    role.in?(%w[sender lawyer ecommerce_seller])
  end

  def lawyer?
    role == "lawyer"
  end

  def ecommerce_seller?
    role == "ecommerce_seller"
  end

  def has_saved_signature?
    saved_signature.attached?
  end

  def signature_required_on_registration?
    user_type_lawyer? || user_type_courier?
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
