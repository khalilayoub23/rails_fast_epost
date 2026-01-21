# frozen_string_literal: true

require "securerandom"

namespace :demo do
  desc "Create sample tasks, payments, and enqueue background jobs"
  task setup: :environment do
    puts "📦 Ensuring base demo records..."
    carrier = Carrier.first || Carrier.create!(
      name: "Demo Carrier",
      email: "demo-carrier@example.com",
      carrier_type: "express",
      address: "123 Logistics Way, Chicago, IL"
    )

    customer = Customer.first || Customer.create!(
      name: "Demo Customer",
      email: "customer@example.com",
      address: "500 Customer Blvd, Chicago, IL",
      phones: [ "+1-555-0100" ].to_json,
      category: :business
    )

    sender = Sender.first || Sender.create!(
      name: "Demo Sender",
      email: "sender@example.com",
      phone: "+1-555-0101",
      address: "700 Sender St, Chicago, IL",
      sender_type: :business,
      company_name: "Demo Sender LLC"
    )

    messenger = Messenger.first || Messenger.create!(
      name: "Demo Courier",
      email: "courier@example.com",
      phone: "+1-555-0102",
      status: :available,
      vehicle_type: :motorcycle,
      carrier: carrier,
      employee_id: "EMP-DEMO-001",
      current_location: { lat: 41.8781, lng: -87.6298 }
    )

    lawyer = Lawyer.first || Lawyer.create!(
      name: "Demo Lawyer",
      email: "lawyer@example.com",
      phone: "+1-555-LAW-000",
      license_number: "LAW-DEMO-001",
      specialization: :contract,
      bar_association: "Demo Bar",
      certifications: [],
      notes: "Demo legal contact"
    )

    puts "🧾 Creating demo tasks..."
    tasks = 3.times.map do |i|
      Task.create!(
        customer: customer,
        carrier: carrier,
        sender: sender,
        messenger: messenger,
        lawyer: lawyer,
        package_type: "Documents ##{i + 1}",
        start: "Chicago Hub #{i + 1}",
        target: "Delivery Zone #{i + 1}",
        delivery_time: 2.days.from_now,
        priority: Task.priorities.keys.fetch(i % Task.priorities.size),
        pickup_address: "123 Pickup Rd, Chicago, IL",
        pickup_contact_phone: "+1-555-020#{i}",
        pickup_notes: "Demo task ##{i + 1}"
      )
    end

    puts "💳 Creating payments linked to tasks and carrier..."
    payments = tasks.map.with_index do |task, idx|
      payment = Payment.create!(
        category: :delivery_fee,
        payment_type: :per_task,
        payable: carrier,
        task: task,
        provider: "stripe",
        external_id: "demo-ext-#{task.barcode}",
        gateway_status: :succeeded,
        amount_cents: 2000 + (idx * 500),
        currency: "USD",
        metadata: { demo: true, task_barcode: task.barcode }
      )
      PaymentsTask.find_or_create_by!(task: task, payment: payment)
      payment
    end

    puts "📄 Creating a demo delivery for PDF processing..."
    delivery = Delivery.create!(
      sender: ensure_user("delivery-sender@example.com", role: :manager, user_type: :sender),
      recipient: ensure_user("delivery-recipient@example.com", role: :sender, user_type: :recipient),
      courier: ensure_user("delivery-courier@example.com", role: :carrier_staff, user_type: :courier),
      case_number: "CASE-DEMO-#{SecureRandom.hex(2).upcase}",
      notes: "Demo delivery for PDF job",
      status: :draft
    )

    puts "🚀 Enqueuing background jobs (Solid Queue)..."
    CarrierPayoutSyncJob.perform_later
    PaymentsSyncJob.perform_later
    ProcessDeliveryPdfJob.perform_later(delivery.id)

    queued = SolidQueue::Job.order(created_at: :desc).limit(10).pluck(:id, :class_name, :queue_name)
    puts "Queued jobs:" if queued.any?
    queued.each { |id, cls, queue| puts " - ##{id} #{cls} (queue: #{queue})" }

    puts "✅ Demo setup complete: #{tasks.count} tasks, #{payments.count} payments, delivery ##{delivery.case_number}"
  end

  def ensure_user(email, role:, user_type:)
    User.find_or_create_by!(email: email) do |user|
      user.password = "password"
      user.password_confirmation = "password"
      user.role = role
      user.user_type = user_type
    end
  end
end
