class DefaultAccountsProvisioner
  DEFAULT_ACCOUNTS = [
    { role: "admin",              email_env: "DEFAULT_ADMIN_EMAIL",              fallback_email: "admin@example.com" },
    { role: "operations_manager", email_env: "DEFAULT_OPS_MANAGER_EMAIL",       fallback_email: "ops@example.com" },
    { role: "manager",            email_env: "DEFAULT_MANAGER_EMAIL",           fallback_email: "manager@example.com" },
    { role: "sender",             email_env: "DEFAULT_VIEWER_EMAIL",            fallback_email: "viewer@example.com" }
  ].freeze

  def self.ensure!
    new.ensure!
  end

  def ensure!
    return unless provisionable_environment?
    return unless users_table_ready?

    DEFAULT_ACCOUNTS.each do |config|
      desired_email = ENV.fetch(config[:email_env], config[:fallback_email])
      ensure_account(
        email: desired_email,
        fallback_email: config[:fallback_email],
        role: config[:role]
      )
    end
  end

  private

  def provisionable_environment?
    Rails.env.development?
  end

  def users_table_ready?
    ActiveRecord::Base.connection.table_exists?(:users)
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad
    false
  end

  def ensure_account(email:, fallback_email:, role:)
    password = ENV.fetch("DEFAULT_USER_PASSWORD", "password")

    if (user = User.find_by(email: email))
      return sync_role(user, role)
    end

    if (fallback_user = find_fallback_user(email: email, fallback_email: fallback_email))
      return sync_fallback(fallback_user, email: email, role: role)
    end

    User.create!(
      email: email,
      password: password,
      password_confirmation: password,
      role: role
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[DefaultAccountsProvisioner] Unable to provision #{role}: #{e.message}")
    nil
  end

  def find_fallback_user(email:, fallback_email:)
    return nil if fallback_email.blank? || fallback_email == email

    fallback_user = User.find_by(email: fallback_email)
    return nil unless fallback_user

    # Only treat the fallback account as replaceable if it looks like a placeholder
    # (tests and dev provisioning expect we don't rename a real, fully-profiled user).
    return nil if fallback_user.full_name.present?

    fallback_user
  end

  def sync_role(user, role)
    return user unless user
    return user unless enforce_role_sync?

    user.update!(role: role) if user.role != role
    user
  end

  def sync_fallback(user, email:, role:)
    return unless user
    return unless enforce_role_sync?

    user.update!(email: email) if user.email != email
    sync_role(user, role)
  end

  def enforce_role_sync?
    default = Rails.env.test? ? "true" : "false"
    ENV.fetch("DEFAULT_ACCOUNT_ENFORCE_ROLES", default) == "true"
  end
end
