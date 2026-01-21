namespace :dev do
  desc "Create or refresh a sample tracking task for manual testing"
  task seed_tracking_sample: :environment do
    customer = Customer.find_or_initialize_by(email: "debug-customer@example.com") do |record|
      record.name = "Debug Customer"
      record.category = :individual
      record.address = "1 Debug Way, Sample City"
      record.phones = [ "+1-555-0100" ]
    end
    customer.allow_partial_profile = true if customer.respond_to?(:allow_partial_profile=)
    customer.save!

    carrier = Carrier.find_or_initialize_by(email: "debug-carrier@example.com") do |record|
      record.name = "Debug Carrier"
      record.carrier_type = "independent"
      record.address = "2 Carrier Plaza, Sample City"
    end
    carrier.save!

    barcode = ENV.fetch("BARCODE", "DEBUGTRACK-FAIL-001")
    delivery_time = 2.days.from_now.change(min: 0)

    task = Task.find_or_initialize_by(barcode: barcode)
    task.assign_attributes(
      customer: customer,
      carrier: carrier,
      package_type: "debug_parcel",
      start: "Debug Origin Hub",
      target: "Debug Destination Center",
      status: :delivered,
      delivery_time: delivery_time,
      failed_attempts: 2,
      last_failure_note: "Recipient was unavailable",
      awaiting_customer_response: false,
      stored_until: nil,
      priority: :express
    )
    task.save!

    timeline = {
      order_created: 6.hours.ago,
      package_picked_up: 4.hours.ago,
      failed_first: 3.hours.ago,
      failed_second: 2.hours.ago,
      out_for_delivery: 90.minutes.ago,
      delivered: 30.minutes.ago
    }

    task.tracking_events.destroy_all

    task.record_tracking_event!(
      title: "Order Created",
      event_type: "created",
      status: "pending",
      occurred_at: timeline[:order_created],
      description: "Shipment registered and confirmed."
    )

    task.record_tracking_event!(
      title: "Package Picked Up",
      event_type: "picked_up",
      status: "in_transit",
      occurred_at: timeline[:package_picked_up],
      description: "Courier collected the parcel from sender."
    )

    task.record_tracking_event!(
      title: "Delivery Attempt Failed",
      event_type: "failed",
      status: "failed",
      occurred_at: timeline[:failed_first],
      description: "Recipient not available. Left door tag.",
      metadata: { attempt_number: 1, stored_until: 1.day.from_now.iso8601 }
    )

    task.record_tracking_event!(
      title: "Delivery Attempt Failed",
      event_type: "failed",
      status: "failed",
      occurred_at: timeline[:failed_second],
      description: "Gate code invalid. Customer notified.",
      metadata: { attempt_number: 2 }
    )

    task.record_tracking_event!(
      title: "Out for Delivery",
      event_type: "out_for_delivery",
      status: "in_transit",
      occurred_at: timeline[:out_for_delivery],
      description: "Messenger en route to destination."
    )

    task.record_tracking_event!(
      title: "Delivered",
      event_type: "delivered",
      status: "delivered",
      occurred_at: timeline[:delivered],
      description: "Package handed to recipient."
    )

    puts "Sample tracking task ready!"
    puts "Barcode: #{task.barcode}"
    puts "Visit /pages/track_parcel?tracking_number=#{task.barcode}"
  end
end
