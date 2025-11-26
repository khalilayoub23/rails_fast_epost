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

# Create operations manager user
operations_manager = User.find_or_create_by!(email: "ops@example.com") do |user|
  user.password = "password"
  user.password_confirmation = "password"
  user.role = "operations_manager"
end
puts "✅ Operations manager user created: ops@example.com / password"

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
Messenger.destroy_all
Sender.destroy_all
Lawyer.destroy_all
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

# Link operations manager to top carriers for dashboard scoping
if defined?(operations_manager) && operations_manager.persisted?
  carriers.first(2).each do |carrier|
    CarrierMembership.find_or_create_by!(user: operations_manager, carrier: carrier)
  end
  puts "🔗 Operations manager assigned to #{carriers.first(2).map(&:name).join(', ')}"
end

# Create Senders
puts "Creating senders..."
senders = [
  { name: "John Doe", email: "john.doe@example.com", phone: "+1234567890", address: "123 Main Street, Springfield, IL 62701", sender_type: :individual, notes: "Regular customer, sends packages monthly" },
  { name: "Acme Corporation", email: "shipping@acme.com", phone: "+1234567891", address: "456 Business Blvd, Suite 200, Chicago, IL 60601", sender_type: :business, company_name: "Acme Corporation", tax_id: "12-3456789", business_registration: "IL-ACME-2020-001", notes: "High-volume shipper, priority handling" },
  { name: "Department of Health", email: "logistics@health.gov", phone: "+1234567892", address: "789 Government Way, Washington, DC 20500", sender_type: :government, company_name: "U.S. Department of Health", tax_id: "GOV-HEALTH-123", notes: "Government entity, special documentation required" },
  { name: "Jane Smith", email: "jane.smith@gmail.com", phone: "+1234567893", address: "321 Oak Avenue, Apt 5B, Boston, MA 02101", sender_type: :individual, notes: "Online seller, frequent small packages" },
  { name: "Tech Solutions Inc", email: "mail@techsolutions.com", phone: "+1234567894", address: "555 Innovation Drive, San Francisco, CA 94102", sender_type: :business, company_name: "Tech Solutions Inc", tax_id: "94-7654321", business_registration: "CA-TECH-2021-456", notes: "Tech company, ships equipment and parts" }
].map do |attrs|
  Sender.create!(attrs)
end

# Create Messengers
puts "Creating messengers..."
messengers = [
  { name: "Mike Johnson", email: "mike.j@fastdelivery.com", phone: "+1555000001", carrier: carriers[0], status: :available, vehicle_type: :motorcycle, license_plate: "MOTO-123", license_number: "DL-12345678", employee_id: "EMP-001", total_deliveries: 150, on_time_rate: 0.95, current_location: { latitude: 41.8781, longitude: -87.6298 }, notes: "Experienced messenger, knows city routes well" },
  { name: "Sarah Williams", email: "sarah.w@fastdelivery.com", phone: "+1555000002", carrier: carriers[0], status: :busy, vehicle_type: :van, license_plate: "VAN-456", license_number: "DL-87654321", employee_id: "EMP-002", total_deliveries: 220, on_time_rate: 0.98, current_location: { latitude: 41.8500, longitude: -87.6500 }, notes: "Top performer, handles large deliveries" },
  { name: "Carlos Rodriguez", email: "carlos.r@speedpost.com", phone: "+1555000003", carrier: carriers[1], status: :available, vehicle_type: :bicycle, license_number: "DL-11223344", employee_id: "EMP-003", total_deliveries: 80, on_time_rate: 0.92, current_location: { latitude: 41.9000, longitude: -87.6000 }, notes: "Eco-friendly option, city center specialist" },
  { name: "Emily Chen", email: "emily.c@speedpost.com", phone: "+1555000004", carrier: carriers[1], status: :offline, vehicle_type: :car, license_plate: "CAR-789", license_number: "DL-55667788", employee_id: "EMP-004", total_deliveries: 180, on_time_rate: 0.96, notes: "Currently off-duty, suburban routes specialist" },
  { name: "David Martinez", email: "david.m@fastdelivery.com", phone: "+1555000005", carrier: carriers[0], status: :busy, vehicle_type: :truck, license_plate: "TRUCK-101", license_number: "CDL-99887766", employee_id: "EMP-005", total_deliveries: 120, on_time_rate: 0.94, current_location: { latitude: 41.8200, longitude: -87.7000 }, notes: "Heavy cargo specialist, commercial deliveries" }
].map do |attrs|
  Messenger.create!(attrs)
end

# Create Lawyers
puts "Creating lawyers..."
lawyers = [
  {
    name: "Sarah Chen",
    email: "sarah.chen@legalsolutions.com",
    phone: "+1-555-LAW-0001",
    license_number: "LAW-2018-001",
    specialization: :customs,
    bar_association: "American Bar Association",
    certifications: [
      { name: "Customs Law Certification", issuer: "International Trade Commission", year: 2020 },
      { name: "Import/Export Specialist", issuer: "U.S. Customs and Border Protection", year: 2019 }
    ],
    active: true,
    notes: "Specializes in international customs clearance and trade compliance. 10+ years experience with complex customs cases."
  },
  {
    name: "Michael Rodriguez",
    email: "m.rodriguez@tradelaw.com",
    phone: "+1-555-LAW-0002",
    license_number: "LAW-2015-042",
    specialization: :international_trade,
    bar_association: "New York State Bar",
    certifications: [
      { name: "International Trade Law", issuer: "International Chamber of Commerce", year: 2018 }
    ],
    active: true,
    notes: "Expert in trade agreements, tariffs, and international shipping regulations. Fluent in Spanish and English."
  },
  {
    name: "Jennifer Park",
    email: "jennifer.park@contractlaw.com",
    phone: "+1-555-LAW-0003",
    license_number: "LAW-2020-115",
    specialization: :contract,
    bar_association: "California Bar Association",
    active: true,
    notes: "Contract law specialist for logistics and shipping agreements. Recently joined the firm."
  },
  {
    name: "David Thompson",
    email: "david.thompson@corporatelaw.com",
    phone: "+1-555-LAW-0004",
    license_number: "LAW-2012-008",
    specialization: :corporate,
    bar_association: "Illinois State Bar",
    certifications: [
      { name: "Corporate Compliance Certification", issuer: "Society of Corporate Compliance and Ethics", year: 2016 }
    ],
    active: true,
    notes: "Corporate law expert handling business entity matters and regulatory compliance."
  },
  {
    name: "Maria Garcia",
    email: "maria.garcia@immigrationlaw.com",
    phone: "+1-555-LAW-0005",
    license_number: "LAW-2017-067",
    specialization: :immigration,
    bar_association: "Texas Bar Association",
    certifications: [
      { name: "Immigration Law Specialist", issuer: "American Immigration Lawyers Association", year: 2019 },
      { name: "Visa Processing Expert", issuer: "U.S. Department of State", year: 2020 }
    ],
    active: true,
    notes: "Immigration specialist assisting with worker visas and international personnel documentation."
  },
  {
    name: "Robert Wilson",
    email: "robert.wilson@iplaw.com",
    phone: "+1-555-LAW-0006",
    license_number: "LAW-2010-023",
    specialization: :intellectual_property,
    bar_association: "Florida Bar Association",
    active: true,
    notes: "IP law specialist for trademark and patent matters in international shipping. 15+ years experience."
  },
  {
    name: "Amanda Foster",
    email: "amanda.foster@generalpractice.com",
    phone: "+1-555-LAW-0007",
    license_number: "LAW-2019-089",
    specialization: :general_practice,
    bar_association: "Virginia Bar Association",
    active: false,
    notes: "General practice attorney. Currently on sabbatical leave."
  },
  {
    name: "James Liu",
    email: "james.liu@litigationlaw.com",
    phone: "+1-555-LAW-0008",
    license_number: "LAW-2014-051",
    specialization: :litigation,
    bar_association: "Washington Bar Association",
    certifications: [
      { name: "Certified Litigation Specialist", issuer: "National Board of Trial Advocacy", year: 2017 }
    ],
    active: true,
    notes: "Litigation expert for shipping disputes and contract enforcement cases."
  }
].map do |attrs|
  Lawyer.create!(attrs)
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
puts "  - #{Sender.count} senders"
puts "  - #{Messenger.count} messengers"
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
puts "📮 Sender types:"
Sender.group(:sender_type).count.each { |type, count| puts "  - #{type}: #{count}" }
puts
puts "🚴 Messenger statuses:"
Messenger.group(:status).count.each { |status, count| puts "  - #{status}: #{count}" }
puts

# Create Document Templates
puts "Creating document templates..."

# Template 1: Power of Attorney (Prawn)
DocumentTemplate.find_or_create_by!(name: "Power of Attorney") do |template|
  template.description = "Legal document authorizing an agent to act on behalf of a principal"
  template.template_type = :prawn_template
  template.category = "Power of Attorney"
  template.active = true
  template.content = <<~CONTENT
    # POWER OF ATTORNEY

    I, {{principal_name}}, residing at {{principal_address}}, hereby appoint {{agent_name}}, residing at {{agent_address}}, as my attorney-in-fact (Agent) to act in my name, place, and stead in any way which I myself could do, if I were personally present, with respect to the following matters:

    ## Scope of Authority

    {{authority_description}}

    ## Effective Date

    This Power of Attorney shall become effective on {{effective_date}} and shall remain in effect until {{expiration_date}} unless earlier revoked by me in writing.

    ## Special Instructions

    {{special_instructions}}

    ## Signature

    IN WITNESS WHEREOF, I have hereunto set my hand this {{signature_date}}.

    Principal Signature: _______________________________
    Print Name: {{principal_name}}
    Date: {{signature_date}}

    Agent Acceptance: _______________________________
    Print Name: {{agent_name}}
    Date: {{agent_acceptance_date}}
  CONTENT
  template.variables = {
    "principal_name" => { "type" => "string", "label" => "Principal Full Name", "required" => true },
    "principal_address" => { "type" => "string", "label" => "Principal Address", "required" => true },
    "agent_name" => { "type" => "string", "label" => "Agent Full Name", "required" => true },
    "agent_address" => { "type" => "string", "label" => "Agent Address", "required" => true },
    "authority_description" => { "type" => "text", "label" => "Description of Authority", "required" => true },
    "effective_date" => { "type" => "date", "label" => "Effective Date", "required" => true },
    "expiration_date" => { "type" => "date", "label" => "Expiration Date", "required" => false },
    "special_instructions" => { "type" => "text", "label" => "Special Instructions", "required" => false },
    "signature_date" => { "type" => "date", "label" => "Signature Date", "required" => true },
    "agent_acceptance_date" => { "type" => "date", "label" => "Agent Acceptance Date", "required" => true }
  }
end

# Template 2: Shipping Authorization Letter (Prawn)
DocumentTemplate.find_or_create_by!(name: "Shipping Authorization Letter") do |template|
  template.description = "Authorization letter for shipping and customs clearance"
  template.template_type = :prawn_template
  template.category = "Shipping Document"
  template.active = true
  template.content = <<~CONTENT
    # SHIPPING AUTHORIZATION LETTER

    Date: {{letter_date}}

    To Whom It May Concern:

    ## Authorization Statement

    I, {{shipper_name}}, holder of passport/ID number {{shipper_id}}, hereby authorize {{authorized_party}} to act as my representative for the following shipment:

    ## Shipment Details

    Tracking Number: {{tracking_number}}
    Package Description: {{package_description}}
    Destination: {{destination_address}}
    Declared Value: {{declared_value}}

    ## Authorized Actions

    The authorized party is permitted to:
    - Clear customs on my behalf
    - Sign documents related to this shipment
    - Pay duties and taxes if required
    - Receive the shipment at destination

    ## Contact Information

    Shipper Name: {{shipper_name}}
    Phone: {{shipper_phone}}
    Email: {{shipper_email}}

    Authorized Party: {{authorized_party}}
    Phone: {{authorized_phone}}

    ## Signature

    Shipper Signature: _______________________________
    Print Name: {{shipper_name}}
    Date: {{signature_date}}
  CONTENT
  template.variables = {
    "letter_date" => { "type" => "date", "label" => "Letter Date", "required" => true },
    "shipper_name" => { "type" => "string", "label" => "Shipper Full Name", "required" => true },
    "shipper_id" => { "type" => "string", "label" => "Shipper ID/Passport", "required" => true },
    "authorized_party" => { "type" => "string", "label" => "Authorized Party Name", "required" => true },
    "tracking_number" => { "type" => "string", "label" => "Tracking Number", "required" => true },
    "package_description" => { "type" => "text", "label" => "Package Description", "required" => true },
    "destination_address" => { "type" => "text", "label" => "Destination Address", "required" => true },
    "declared_value" => { "type" => "string", "label" => "Declared Value", "required" => true },
    "shipper_phone" => { "type" => "string", "label" => "Shipper Phone", "required" => true },
    "shipper_email" => { "type" => "string", "label" => "Shipper Email", "required" => true },
    "authorized_phone" => { "type" => "string", "label" => "Authorized Party Phone", "required" => true },
    "signature_date" => { "type" => "date", "label" => "Signature Date", "required" => true }
  }
end

# Template 3: Consent for International Shipping (Prawn)
DocumentTemplate.find_or_create_by!(name: "Parental Consent for Minor's Package") do |template|
  template.description = "Consent form for shipping packages to/from minors"
  template.template_type = :prawn_template
  template.category = "Consent Form"
  template.active = true
  template.content = <<~CONTENT
    # PARENTAL CONSENT FOR MINOR'S PACKAGE

    ## Parent/Guardian Information

    I, {{parent_name}}, parent/legal guardian of {{minor_name}}, born on {{minor_dob}}, hereby provide consent for the following:

    ## Purpose

    {{consent_purpose}}

    ## Package Details

    Package Type: {{package_type}}
    Estimated Value: {{package_value}}
    Contents Description: {{contents_description}}

    ## Shipping Information

    From: {{origin_address}}
    To: {{destination_address}}
    Carrier: {{carrier_name}}

    ## Declaration

    I declare that I have full legal authority to provide this consent and that all information provided is true and accurate.

    ## Contact Information

    Parent/Guardian Name: {{parent_name}}
    Relationship: {{relationship}}
    Phone: {{parent_phone}}
    Email: {{parent_email}}

    ## Signature

    Parent/Guardian Signature: _______________________________
    Print Name: {{parent_name}}
    Date: {{signature_date}}
  CONTENT
  template.variables = {
    "parent_name" => { "type" => "string", "label" => "Parent/Guardian Name", "required" => true },
    "minor_name" => { "type" => "string", "label" => "Minor's Name", "required" => true },
    "minor_dob" => { "type" => "date", "label" => "Minor's Date of Birth", "required" => true },
    "consent_purpose" => { "type" => "text", "label" => "Purpose of Consent", "required" => true },
    "package_type" => { "type" => "string", "label" => "Package Type", "required" => true },
    "package_value" => { "type" => "string", "label" => "Package Value", "required" => true },
    "contents_description" => { "type" => "text", "label" => "Contents Description", "required" => true },
    "origin_address" => { "type" => "text", "label" => "Origin Address", "required" => true },
    "destination_address" => { "type" => "text", "label" => "Destination Address", "required" => true },
    "carrier_name" => { "type" => "string", "label" => "Carrier Name", "required" => true },
    "relationship" => { "type" => "string", "label" => "Relationship to Minor", "required" => true },
    "parent_phone" => { "type" => "string", "label" => "Phone Number", "required" => true },
    "parent_email" => { "type" => "string", "label" => "Email Address", "required" => true },
    "signature_date" => { "type" => "date", "label" => "Signature Date", "required" => true }
  }
end

# Template 4: Commercial Invoice (Prawn)
DocumentTemplate.find_or_create_by!(name: "Commercial Invoice") do |template|
  template.description = "Invoice for international shipments and customs clearance"
  template.template_type = :prawn_template
  template.category = "Commercial Invoice"
  template.active = true
  template.content = <<~CONTENT
    # COMMERCIAL INVOICE

    Invoice Number: {{invoice_number}}
    Invoice Date: {{invoice_date}}

    ## Seller Information

    Company Name: {{seller_company}}
    Address: {{seller_address}}
    Phone: {{seller_phone}}
    Tax ID: {{seller_tax_id}}

    ## Buyer Information

    Company Name: {{buyer_company}}
    Address: {{buyer_address}}
    Phone: {{buyer_phone}}
    Tax ID: {{buyer_tax_id}}

    ## Shipment Details

    Tracking Number: {{tracking_number}}
    Shipping Method: {{shipping_method}}
    Terms of Sale: {{terms_of_sale}}
    Country of Origin: {{country_of_origin}}

    ## Items Description

    {{items_table}}

    ## Totals

    Subtotal: {{subtotal}}
    Shipping: {{shipping_cost}}
    Insurance: {{insurance_cost}}
    Total Value: {{total_value}}

    ## Declaration

    I declare that all information on this invoice is true and correct.

    Signature: _______________________________
    Name: {{declarant_name}}
    Title: {{declarant_title}}
    Date: {{signature_date}}
  CONTENT
  template.variables = {
    "invoice_number" => { "type" => "string", "label" => "Invoice Number", "required" => true },
    "invoice_date" => { "type" => "date", "label" => "Invoice Date", "required" => true },
    "seller_company" => { "type" => "string", "label" => "Seller Company", "required" => true },
    "seller_address" => { "type" => "text", "label" => "Seller Address", "required" => true },
    "seller_phone" => { "type" => "string", "label" => "Seller Phone", "required" => true },
    "seller_tax_id" => { "type" => "string", "label" => "Seller Tax ID", "required" => true },
    "buyer_company" => { "type" => "string", "label" => "Buyer Company", "required" => true },
    "buyer_address" => { "type" => "text", "label" => "Buyer Address", "required" => true },
    "buyer_phone" => { "type" => "string", "label" => "Buyer Phone", "required" => true },
    "buyer_tax_id" => { "type" => "string", "label" => "Buyer Tax ID", "required" => false },
    "tracking_number" => { "type" => "string", "label" => "Tracking Number", "required" => true },
    "shipping_method" => { "type" => "string", "label" => "Shipping Method", "required" => true },
    "terms_of_sale" => { "type" => "string", "label" => "Terms of Sale (Incoterms)", "required" => true },
    "country_of_origin" => { "type" => "string", "label" => "Country of Origin", "required" => true },
    "items_table" => { "type" => "text", "label" => "Items (Description | Qty | Unit Price)", "required" => true },
    "subtotal" => { "type" => "string", "label" => "Subtotal", "required" => true },
    "shipping_cost" => { "type" => "string", "label" => "Shipping Cost", "required" => true },
    "insurance_cost" => { "type" => "string", "label" => "Insurance Cost", "required" => false },
    "total_value" => { "type" => "string", "label" => "Total Value", "required" => true },
    "declarant_name" => { "type" => "string", "label" => "Declarant Name", "required" => true },
    "declarant_title" => { "type" => "string", "label" => "Declarant Title", "required" => true },
    "signature_date" => { "type" => "date", "label" => "Signature Date", "required" => true }
  }
end

# Template 5: Certificate of Origin (Prawn)
DocumentTemplate.find_or_create_by!(name: "Certificate of Origin") do |template|
  template.description = "Certificate declaring the country of origin for goods"
  template.template_type = :prawn_template
  template.category = "Certificate of Origin"
  template.active = true
  template.content = <<~CONTENT
    # CERTIFICATE OF ORIGIN

    Certificate Number: {{certificate_number}}
    Issue Date: {{issue_date}}

    ## Exporter Information

    Company Name: {{exporter_company}}
    Address: {{exporter_address}}
    Country: {{exporter_country}}

    ## Consignee Information

    Company Name: {{consignee_company}}
    Address: {{consignee_address}}
    Country: {{consignee_country}}

    ## Transportation Details

    Means of Transport: {{transport_method}}
    Departure Date: {{departure_date}}
    Port of Loading: {{port_of_loading}}
    Port of Discharge: {{port_of_discharge}}

    ## Goods Description

    Description of Goods: {{goods_description}}
    HS Code: {{hs_code}}
    Quantity: {{quantity}}
    Weight: {{weight}}
    Value: {{declared_value}}

    ## Declaration of Origin

    Country of Origin: {{country_of_origin}}

    The undersigned hereby declares that the above details and statements are correct and that all goods described were produced or manufactured in {{country_of_origin}}.

    ## Certification

    Authorized Signature: _______________________________
    Name: {{certifier_name}}
    Title: {{certifier_title}}
    Company: {{certifier_company}}
    Date: {{certification_date}}

    Official Stamp: [SPACE FOR STAMP]
  CONTENT
  template.variables = {
    "certificate_number" => { "type" => "string", "label" => "Certificate Number", "required" => true },
    "issue_date" => { "type" => "date", "label" => "Issue Date", "required" => true },
    "exporter_company" => { "type" => "string", "label" => "Exporter Company", "required" => true },
    "exporter_address" => { "type" => "text", "label" => "Exporter Address", "required" => true },
    "exporter_country" => { "type" => "string", "label" => "Exporter Country", "required" => true },
    "consignee_company" => { "type" => "string", "label" => "Consignee Company", "required" => true },
    "consignee_address" => { "type" => "text", "label" => "Consignee Address", "required" => true },
    "consignee_country" => { "type" => "string", "label" => "Consignee Country", "required" => true },
    "transport_method" => { "type" => "string", "label" => "Transport Method", "required" => true },
    "departure_date" => { "type" => "date", "label" => "Departure Date", "required" => true },
    "port_of_loading" => { "type" => "string", "label" => "Port of Loading", "required" => true },
    "port_of_discharge" => { "type" => "string", "label" => "Port of Discharge", "required" => true },
    "goods_description" => { "type" => "text", "label" => "Goods Description", "required" => true },
    "hs_code" => { "type" => "string", "label" => "HS Code", "required" => true },
    "quantity" => { "type" => "string", "label" => "Quantity", "required" => true },
    "weight" => { "type" => "string", "label" => "Weight", "required" => true },
    "declared_value" => { "type" => "string", "label" => "Declared Value", "required" => true },
    "country_of_origin" => { "type" => "string", "label" => "Country of Origin", "required" => true },
    "certifier_name" => { "type" => "string", "label" => "Certifier Name", "required" => true },
    "certifier_title" => { "type" => "string", "label" => "Certifier Title", "required" => true },
    "certifier_company" => { "type" => "string", "label" => "Certifier Company", "required" => true },
    "certification_date" => { "type" => "date", "label" => "Certification Date", "required" => true }
  }
end

# Legal Document Templates (Gap #5)
puts "Creating legal document templates..."

DocumentTemplate.find_or_create_by!(name: "Basic Customs Declaration") do |template|
  template.description = "Simple customs declaration form for international shipments and packages"
  template.content = File.read(Rails.root.join("app", "views", "legal_documents", "declarations", "basic_declaration.html.erb"))
  template.template_type = "prawn_template"
  template.category = "legal"
  template.active = true
  template.variables = {
    "sender_name" => { "type" => "string", "label" => "Sender Full Name", "required" => true },
    "sender_address" => { "type" => "text", "label" => "Sender Address", "required" => true },
    "sender_phone" => { "type" => "string", "label" => "Sender Phone", "required" => true },
    "sender_email" => { "type" => "string", "label" => "Sender Email", "required" => true },
    "recipient_name" => { "type" => "string", "label" => "Recipient Full Name", "required" => true },
    "recipient_address" => { "type" => "text", "label" => "Recipient Address", "required" => true },
    "recipient_phone" => { "type" => "string", "label" => "Recipient Phone", "required" => true },
    "package_description" => { "type" => "text", "label" => "Package Description", "required" => true },
    "quantity" => { "type" => "number", "label" => "Quantity", "required" => true },
    "weight" => { "type" => "number", "label" => "Total Weight (kg)", "required" => true },
    "currency" => { "type" => "string", "label" => "Currency (e.g., USD, EUR)", "required" => true },
    "declared_value" => { "type" => "number", "label" => "Declared Value", "required" => true },
    "shipment_purpose" => { "type" => "string", "label" => "Purpose of Shipment", "required" => true },
    "declaration_date" => { "type" => "date", "label" => "Declaration Date", "required" => true },
    "declaration_place" => { "type" => "string", "label" => "Place of Declaration", "required" => true }
  }
end

DocumentTemplate.find_or_create_by!(name: "Detailed Customs Declaration") do |template|
  template.description = "Comprehensive customs declaration for international trade and commercial shipments with full item details and certifications"
  template.content = File.read(Rails.root.join("app", "views", "legal_documents", "declarations", "detailed_declaration.html.erb"))
  template.template_type = "prawn_template"
  template.category = "legal"
  template.active = true
  template.variables = {
    "declaration_number" => { "type" => "string", "label" => "Declaration Number", "required" => true },
    "declaration_date" => { "type" => "date", "label" => "Declaration Date", "required" => true },
    "sender_name" => { "type" => "string", "label" => "Sender/Exporter Name", "required" => true },
    "sender_business_id" => { "type" => "string", "label" => "Business Registration/ID", "required" => true },
    "sender_address" => { "type" => "text", "label" => "Sender Complete Address", "required" => true },
    "sender_country" => { "type" => "string", "label" => "Country of Origin", "required" => true },
    "sender_phone" => { "type" => "string", "label" => "Sender Phone", "required" => true },
    "sender_email" => { "type" => "string", "label" => "Sender Email", "required" => true },
    "recipient_name" => { "type" => "string", "label" => "Recipient/Consignee Name", "required" => true },
    "recipient_tax_id" => { "type" => "string", "label" => "Recipient Tax/VAT Number", "required" => true },
    "recipient_address" => { "type" => "text", "label" => "Recipient Complete Address", "required" => true },
    "recipient_country" => { "type" => "string", "label" => "Country of Destination", "required" => true },
    "recipient_phone" => { "type" => "string", "label" => "Recipient Phone", "required" => true },
    "item_description" => { "type" => "text", "label" => "Item Description", "required" => true },
    "hs_code" => { "type" => "string", "label" => "HS Code", "required" => true },
    "item_quantity" => { "type" => "number", "label" => "Item Quantity", "required" => true },
    "item_weight" => { "type" => "number", "label" => "Item Unit Weight (kg)", "required" => true },
    "currency" => { "type" => "string", "label" => "Currency", "required" => true },
    "item_unit_value" => { "type" => "number", "label" => "Item Unit Value", "required" => true },
    "item_total_value" => { "type" => "number", "label" => "Item Total Value", "required" => true },
    "total_weight" => { "type" => "number", "label" => "Total Gross Weight (kg)", "required" => true },
    "net_weight" => { "type" => "number", "label" => "Total Net Weight (kg)", "required" => true },
    "total_declared_value" => { "type" => "number", "label" => "Total Declared Value", "required" => true },
    "transport_mode" => { "type" => "string", "label" => "Mode of Transport (Air/Sea/Road)", "required" => true },
    "incoterms" => { "type" => "string", "label" => "Shipping Terms (Incoterms)", "required" => true },
    "shipment_purpose" => { "type" => "string", "label" => "Purpose of Shipment", "required" => true },
    "insurance_value" => { "type" => "number", "label" => "Insurance Value", "required" => false },
    "port_of_loading" => { "type" => "string", "label" => "Port of Loading", "required" => true },
    "port_of_discharge" => { "type" => "string", "label" => "Port of Discharge", "required" => true },
    "certificate_of_origin" => { "type" => "string", "label" => "Certificate of Origin Number", "required" => false },
    "export_license" => { "type" => "string", "label" => "Export License (if applicable)", "required" => false },
    "declarant_name" => { "type" => "string", "label" => "Declarant Name", "required" => true },
    "declarant_title" => { "type" => "string", "label" => "Declarant Title/Position", "required" => true },
    "declaration_place" => { "type" => "string", "label" => "Place of Declaration", "required" => true }
  }
end

DocumentTemplate.find_or_create_by!(name: "Power of Attorney for Customs") do |template|
  template.description = "Legal power of attorney document for customs clearance and shipping operations, authorizing an agent to act on behalf of the principal"
  template.content = File.read(Rails.root.join("app", "views", "legal_documents", "power_of_attorney.html.erb"))
  template.template_type = "prawn_template"
  template.category = "legal"
  template.active = true
  template.variables = {
    "poa_number" => { "type" => "string", "label" => "POA Document Number", "required" => true },
    "execution_date" => { "type" => "date", "label" => "Execution Date", "required" => true },
    "principal_name" => { "type" => "string", "label" => "Principal Full Name/Company", "required" => true },
    "principal_id" => { "type" => "string", "label" => "Principal ID/Registration No", "required" => true },
    "principal_address" => { "type" => "text", "label" => "Principal Address", "required" => true },
    "principal_nationality" => { "type" => "string", "label" => "Principal Nationality/Country", "required" => true },
    "principal_phone" => { "type" => "string", "label" => "Principal Phone", "required" => true },
    "principal_email" => { "type" => "string", "label" => "Principal Email", "required" => true },
    "agent_name" => { "type" => "string", "label" => "Agent/Attorney-in-Fact Name", "required" => true },
    "agent_license" => { "type" => "string", "label" => "Agent License/Registration No", "required" => true },
    "agent_address" => { "type" => "text", "label" => "Agent Address", "required" => true },
    "agent_phone" => { "type" => "string", "label" => "Agent Phone", "required" => true },
    "agent_email" => { "type" => "string", "label" => "Agent Email", "required" => true },
    "jurisdiction" => { "type" => "string", "label" => "Jurisdiction/Country", "required" => true },
    "effective_date" => { "type" => "date", "label" => "Effective Date", "required" => true },
    "expiration_date" => { "type" => "date", "label" => "Expiration Date", "required" => true },
    "scope_description" => { "type" => "text", "label" => "Scope of Authority Description", "required" => true }
  }
end

puts "✅ Created #{DocumentTemplate.count} document templates (including 3 legal templates)"
puts

puts "Ready to showcase your dashboard! 🎉"
