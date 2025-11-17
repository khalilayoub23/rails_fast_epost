# Ensure demo accounts exist locally so developers can log in immediately.
Rails.application.config.after_initialize do
  DefaultAccountsProvisioner.ensure!
end
