# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding the database..."

# Create admin user
puts "Creating admin user..."
User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = "password"
  user.password_confirmation = "password"
  user.role = "admin"
end
puts "✅ Admin user created: admin@example.com / password"

# Create manager user
User.find_or_create_by!(email: "manager@example.com") do |user|
  user.password = "password"
  user.password_confirmation = "password"
  user.role = "manager"
end
puts "✅ Manager user created: manager@example.com / password"

# Create viewer user
User.find_or_create_by!(email: "viewer@example.com") do |user|
  user.password = "password"
  user.password_confirmation = "password"
  user.role = "viewer"
end
puts "✅ Viewer user created: viewer@example.com / password"

# Clear existing data for clean seeding
puts "Clearing existing data..."
Refund.destroy_all
Payment.destroy_all
Task.destroy_all
Customer.destroy_all
Carrier.destroy_all

# Create Carriers
puts "Creating carriers..."
carriers = [
  { name: "DHL Express", email: "contact@dhl.com", carrier_type: "express", address: "123 Logistics Ave, Shipping City" },
  { name: "FedEx Ground", email: "support@fedex.com", carrier_type: "ground", address: "456 Delivery St, Transport Town" },
  { name: "UPS Worldwide", email: "info@ups.com", carrier_type: "express", address: "789 Package Blvd, Courier County" },
  { name: "USPS Priority", email: "help@usps.gov", carrier_type: "standard", address: "321 Mail Route, Postal Plaza" }
].map do |attrs|
  Carrier.create!(attrs)
end

# Create Customers
puts "Creating customers..."
customers = [
  { name: "Acme Corporation", email: "orders@acme.com", category: 0, address: "100 Business Park Dr, Corporate City", phones: [ "+1-555-0101", "+1-555-0102" ] },
  { name: "Global Tech Solutions", email: "shipping@globaltech.io", category: 1, address: "200 Innovation Way, Tech Valley", phones: [ "+1-555-0201" ] },
  { name: "Smith & Associates", email: "logistics@smithlaw.com", category: 0, address: "300 Professional Plaza, Legal District", phones: [ "+1-555-0301", "+1-555-0302" ] },
  { name: "Retail Dynamics Inc", email: "fulfillment@retaildynamics.com", category: 1, address: "400 Commerce Center, Retail Row", phones: [ "+1-555-0401" ] },
  { name: "Healthcare Partners", email: "supplies@healthpartners.org", category: 0, address: "500 Medical Mile, Healthcare Heights", phones: [ "+1-555-0501", "+1-555-0502", "+1-555-0503" ] },
  { name: "Education First", email: "materials@educationfirst.edu", category: 1, address: "600 Campus Circle, University District", phones: [ "+1-555-0601" ] }
].map do |attrs|
  Customer.create!(attrs)
end

# Create Tasks with realistic statuses and timestamps
puts "Creating tasks..."
statuses = [ :pending, :in_transit, :delivered, :failed, :returned ]
package_types = [ "Document", "Package", "Envelope", "Box", "Pallet" ]
locations = [ "New York, NY", "Los Angeles, CA", "Chicago, IL", "Houston, TX", "Phoenix, AZ", "Philadelphia, PA", "San Antonio, TX", "San Diego, CA", "Dallas, TX", "San Jose, CA" ]

tasks = []
60.times do |i|
  task = Task.create!(
    customer: customers.sample,
    carrier: carriers.sample,
    package_type: package_types.sample,
    start: locations.sample,
    target: locations.sample,
    status: statuses.sample,
    barcode: "BC#{(1000000 + i).to_s.rjust(7, '0')}",
    delivery_time: rand(30.days).seconds.ago + rand(60.days).seconds,
    filled_form_url: "https://forms.example.com/task-#{i+1}",
    failure_code: (rand < 0.1 ? rand(1..4) : 0), # 10% chance of failure
    created_at: rand(90.days).seconds.ago,
    updated_at: rand(7.days).seconds.ago
  )
  tasks << task
end

# Create Payments with various statuses and amounts
puts "Creating payments..."
payment_statuses = [ "created", "pending", "succeeded", "failed", "canceled", "refunded" ]
providers = [ "stripe", "local", nil ]
categories = [ :service_fee, :delivery_fee, :insurance, :penalty ]
payment_types = [ :per_task, :lump_sum ]

payments = []
tasks.each_with_index do |task, i|
  # Create 1-3 payments per task
  rand(1..3).times do |j|
    amount = case categories.sample
    when :service_fee then rand(500..2000)  # $5-20
    when :delivery_fee then rand(1000..5000) # $10-50
    when :insurance then rand(300..1500)     # $3-15
    when :penalty then rand(2000..10000)     # $20-100
    end

    payment = Payment.create!(
      task: task,
      payable: task,
      category: categories.sample,
      payment_type: payment_types.sample,
      provider: providers.sample,
      external_id: providers.include?("stripe") ? "pi_#{SecureRandom.hex(12)}" : nil,
      gateway_status: payment_statuses.sample,
      amount_cents: amount,
      currency: "USD",
      payment_url: "https://checkout.stripe.com/pay/#{SecureRandom.hex(8)}",
      stripe_customer_id: "cus_#{SecureRandom.hex(8)}",
      payment_intent_id: "pi_#{SecureRandom.hex(12)}",
      checkout_session_id: "cs_#{SecureRandom.hex(12)}",
      charge_id: "ch_#{SecureRandom.hex(12)}",
      created_at: task.created_at + rand(24.hours).seconds,
      updated_at: task.updated_at
    )
    payments << payment
  end
end

# Create some Refunds for succeeded/refunded payments
puts "Creating refunds..."
refunded_payments = payments.select { |p| p.gateway_status == "refunded" }
succeeded_payments = payments.select { |p| p.gateway_status == "succeeded" }

# Add refunds to all "refunded" payments and some "succeeded" ones
(refunded_payments + succeeded_payments.sample(rand(5..15))).each do |payment|
  refund_amount = rand(payment.amount_cents / 4..payment.amount_cents) # Partial to full refund
  refund_reasons = [ "requested_by_customer", "duplicate", "fraudulent", "order_change" ]

  Refund.create!(
    payment: payment,
    provider: payment.provider || "stripe",
    refund_id: "re_#{SecureRandom.hex(12)}",
    amount_cents: refund_amount,
    currency: payment.currency,
    reason: refund_reasons.sample,
    status: [ "succeeded", "pending", "failed" ].sample,
    balance_transaction_id: "txn_#{SecureRandom.hex(12)}",
    raw: {
      object: "refund",
      metadata: { reason: "Customer requested refund" }
    },
    occurred_at: payment.created_at + rand(30.days).seconds,
    created_at: payment.created_at + rand(30.days).seconds
  )

  # Update payment status if fully refunded
  if refund_amount >= payment.amount_cents
    payment.update!(gateway_status: "refunded")
  end
end

puts "✅ Seeding completed!"
puts
puts "📊 Summary:"
puts "  - #{Carrier.count} carriers"
puts "  - #{Customer.count} customers"
puts "  - #{Task.count} tasks"
puts "  - #{Payment.count} payments"
puts "  - #{Refund.count} refunds"
puts
puts "🚦 Task statuses:"
Task.group(:status).count.each { |status, count| puts "  - #{status}: #{count}" }
puts
puts "💰 Payment statuses:"
Payment.group(:gateway_status).count.each { |status, count| puts "  - #{status}: #{count}" }
puts
puts "Ready to showcase your dashboard! 🎉"
