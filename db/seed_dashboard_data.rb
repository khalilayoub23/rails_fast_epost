# Seed data for dashboard widgets - temporary workaround
# Make payable optional for seeding
puts 'Temporarily making payable optional for seeding...'

Payment.class_eval do
  belongs_to :payable, polymorphic: true, optional: true
end

puts 'Creating sample payments...'

# Create some recent payments with different statuses
10.times do |i|
  begin
    Payment.create!(
      category: :delivery_fee,
      amount_cents: rand(5000..50000),
      currency: 'SEK',
      gateway_status: [ :pending, :succeeded, :failed ].sample,
      payment_type: :per_task,
      provider: 'stripe',
      created_at: rand(30).days.ago
    )
  rescue ActiveRecord::RecordInvalid => e
    puts "Skipping payment #{i+1}: #{e.message}"
  end
end

puts "Created #{Payment.count} total payments"
puts "Succeeded: #{Payment.where(gateway_status: :succeeded).count}"
puts "Pending: #{Payment.where(gateway_status: :pending).count}"
puts "Total revenue: #{Payment.where(gateway_status: :succeeded).sum(:amount_cents) / 100.0} SEK"

# Create some tasks
puts "\nCreating sample tasks..."
10.times do |i|
  Task.create!(
    title: "Sample Task #{i+1}",
    status: [ :pending, :in_progress, :completed ].sample,
    created_at: rand(30).days.ago
  )
rescue ActiveRecord::RecordInvalid => e
  puts "Skipping task creation: #{e.message}"
end

puts "Created #{Task.count} total tasks"

# Create some customers
puts "\nUpdating customer count..."
5.times do |i|
  Customer.find_or_create_by!(email: "customer#{i+1}@example.com") do |c|
    c.name = "Customer #{i+1}"
  end
rescue ActiveRecord::RecordInvalid => e
  puts "Skipping customer: #{e.message}"
end

puts "Total customers: #{Customer.count}"

puts "\n✅ Dashboard seed data created successfully!"
