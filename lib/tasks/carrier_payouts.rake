namespace :carrier_payouts do
  desc "Rebuild carrier payouts from carrier payments (set PURGE=true to remove stale rows)"
  task sync: :environment do
    purge = ActiveModel::Type::Boolean.new.cast(ENV.fetch("PURGE", false))
    CarrierPayoutSyncJob.perform_later(purge: purge)
    puts "Enqueued CarrierPayoutSyncJob (purge=#{purge})"
  end
end
