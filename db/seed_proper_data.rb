# Create proper test data that respects policies
puts 'Creating test data with proper associations...'

# Get or create admin user
admin = User.find_by(email: 'admin@example.com')
puts "Admin user: #{admin&.email} (role: #{admin&.role})"

# Get or create a customer
customer = Customer.first || Customer.create!(
  email: 'customer@example.com',
  name: 'Test Customer',
  phone: '+972501234567'
)
puts "Customer: #{customer.email}"

# Create some tasks first
5.times do |i|
  task = Task.find_or_create_by!(title: "Test Task #{i+1}") do |t|
    t.status = [ :pending, :in_progress, :completed ].sample
    t.created_at = rand(30).days.ago
  end

  # Create payments for each task
  2.times do |j|
    begin
      Payment.create!(
        task: task,
        payable: task,
        category: :delivery_fee,
        amount_cents: rand(5000..50000),
        currency: 'SEK',
        gateway_status: [ :pending, :succeeded, :failed ].sample,
        payment_type: :per_task,
        provider: 'stripe',
        created_at: rand(30).days.ago
      )
    rescue ActiveRecord::RecordInvalid => e
      puts "Skipping payment: #{e.message}"
    end
  end
end

puts "\nDatabase stats:"
puts "Total payments: #{Payment.count}"
puts "Succeeded: #{Payment.where(gateway_status: :succeeded).count}"
puts "Pending: #{Payment.where(gateway_status: :pending).count}"
puts "Revenue: #{Payment.where(gateway_status: :succeeded).sum(:amount_cents) / 100.0} SEK"
puts "Total customers: #{Customer.count}"
puts "Total tasks: #{Task.count}"

# Add more customers if needed
3.times do |i|
  Customer.find_or_create_by!(email: "customer#{i+1}@example.com") do |c|
    c.name = "Customer #{i+1}"
    c.phone = "+97250123456#{i}"
  end
rescue ActiveRecord::RecordInvalid => e
  puts "Skipping customer: #{e.message}"
end

puts "Final customer count: #{Customer.count}"
puts "\n✅ Test data created successfully!"
