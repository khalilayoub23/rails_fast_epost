# Comprehensive seed data for all dashboard widgets
puts "🌱 Seeding comprehensive dashboard data..."

# Create customers first
puts "\n📊 Creating customers..."
10.times do |i|
  Customer.find_or_create_by!(email: "customer#{i+1}@fastepost.com") do |c|
    c.name = "Customer #{i+1}"
    c.phone = "+97250#{1000000 + i}"
  end
rescue => e
  puts "  ⚠️  Customer #{i+1}: #{e.message}"
end

puts "   ✅ Total customers: #{Customer.count}"

# Create tasks
puts "\n📋 Creating tasks..."
20.times do |i|
  Task.find_or_create_by!(title: "Delivery Task ##{1000 + i}") do |t|
    t.status = [ :pending, :in_progress, :completed, :delivered ].sample
    t.description = "Sample delivery task #{i+1}"
    t.created_at = rand(60).days.ago
  end
rescue => e
  puts "  ⚠️  Task #{i+1}: #{e.message}"
end

puts "   ✅ Total tasks: #{Task.count}"

# Create payments linked to tasks
puts "\n💰 Creating payments..."
payment_count = 0
Task.limit(15).each_with_index do |task, i|
  # Create 1-3 payments per task
  rand(1..3).times do |j|
    begin
      Payment.create!(
        task: task,
        payable: task,
        category: [ :service_fee, :delivery_fee, :insurance ].sample,
        amount_cents: rand(10000..100000),
        currency: 'SEK',
        gateway_status: [ :pending, :succeeded, :failed ].sample,
        payment_type: [ :per_task, :lump_sum ].sample,
        provider: 'stripe',
        external_id: "pay_#{SecureRandom.hex(12)}",
        created_at: rand(60).days.ago
      )
      payment_count += 1
    rescue => e
      puts "  ⚠️  Payment for task #{task.id}: #{e.message}"
    end
  end
end

puts "   ✅ Total payments created: #{payment_count}"

# Summary
puts "\n" + "="*50
puts "📈 DASHBOARD DATA SUMMARY"
puts "="*50
puts "Customers:         #{Customer.count}"
puts "Tasks:             #{Task.count}"
puts "Payments:          #{Payment.count}"
puts "  - Succeeded:     #{Payment.where(gateway_status: :succeeded).count}"
puts "  - Pending:       #{Payment.where(gateway_status: :pending).count}"
puts "  - Failed:        #{Payment.where(gateway_status: :failed).count}"
puts "Total Revenue:     #{(Payment.where(gateway_status: :succeeded).sum(:amount_cents) / 100.0).round(2)} SEK"
puts "="*50
puts "✅ Seed completed successfully!"
