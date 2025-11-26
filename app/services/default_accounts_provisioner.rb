class DefaultAccountsProvisioner
  DEFAULT_ACCOUNTS = [
    { role: "admin",              email_env: "DEFAULT_ADMIN_EMAIL",              fallback_email: "admin@example.com" },
    { role: "operations_manager", email_env: "DEFAULT_OPS_MANAGER_EMAIL",       fallback_email: "ops@example.com" },
    { role: "manager",            email_env: "DEFAULT_MANAGER_EMAIL",           fallback_email: "manager@example.com" },
    { role: "viewer",             email_env: "DEFAULT_VIEWER_EMAIL",            fallback_email: "viewer@example.com" }
  ].freeze

  def self.ensure!
    new.ensure!
  end

  def ensure!
    return unless provisionable_environment?
    return unless users_table_ready?

    DEFAULT_ACCOUNTS.each do |config|
      desired_email = ENV.fetch(config[:email_env], config[:fallback_email])
      ensure_account(email: desired_email, role: config[:role])
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

  def ensure_account(email:, role:)
    user = User.find_by(email: email)
    return user if user.present?

    user = User.find_by(role: role)
    if user.present?
      user.update!(email: email)
      return user
    end

    password = ENV.fetch("DEFAULT_USER_PASSWORD", "password")
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
end
