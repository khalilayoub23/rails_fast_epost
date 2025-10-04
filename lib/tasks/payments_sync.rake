namespace :payments do
  desc "Enqueue sync job for pending Stripe payments"
  task sync_pending: :environment do
    PaymentsSyncJob.perform_later
    puts "Enqueued PaymentsSyncJob"
  end
end
