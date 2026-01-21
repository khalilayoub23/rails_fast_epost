# Creates demo draft tasks and adds them to a user's cart.
# Usage:
#   USER_EMAIL=sender@example.com COUNT=15 bin/rails runner script/create_cart_demo_tasks.rb

# Options:
#   DATASET=demo (default) | real
#     - demo: simple synthetic values
#     - real: more realistic-looking (still synthetic) Israeli locations/notes

count = Integer(ENV.fetch("COUNT", "15"))
user_email = ENV["USER_EMAIL"].to_s.strip
dataset = ENV.fetch("DATASET", "demo").to_s.strip.downcase

user_scope = User.all
user_scope = user_scope.where(email: user_email) if user_email.present?
user = user_scope.first

unless user
  puts "No user found. Provide USER_EMAIL=..."
  exit 1
end

customer = Customer.order(:id).first
carrier = Carrier.default_system_carrier

unless customer
  puts "No customers found; create a customer first."
  exit 1
end

cart = Cart.for(user)

created = []

REAL_CITIES = [
  "Tel Aviv", "Jerusalem", "Haifa", "Rishon LeZion", "Petah Tikva", "Netanya",
  "Ashdod", "Herzliya", "Holon", "Bat Yam", "Rehovot", "Kfar Saba",
  "Ramat Gan", "Givatayim", "Beer Sheva", "Eilat", "Modiin-Maccabim-Reut"
].freeze

REAL_STREETS = [
  "Dizengoff St", "Ibn Gabirol St", "Rothschild Blvd", "Jaffa St", "King George St",
  "HaNassi Blvd", "Hertzl St", "Ben Yehuda St", "Weizmann St", "Sokolov St",
  "Begin Rd", "Allenby St", "Bialik St"
].freeze

REAL_PACKAGE_TYPES = [
  "Legal documents", "Court filing", "Signed contract", "Confidential envelope",
  "Small parcel", "Documents + ID copy", "Express envelope"
].freeze

def random_israeli_phone
  "+9725#{rand(10000000..99999999)}"
end

def random_address
  street = REAL_STREETS.sample
  number = rand(1..220)
  city = REAL_CITIES.sample
  "#{street} #{number}, #{city}"
end

def real_pickup_notes(index)
  window_start = (Time.current + rand(15..90).minutes).strftime("%H:%M")
  window_end = (Time.current + rand(120..240).minutes).strftime("%H:%M")
  [
    "Please call on arrival. Pickup window #{window_start}–#{window_end}.",
    "Reception desk pickup. Ask for the package at the front desk.",
    "Handle with care. Do not bend documents.",
    "Contact before pickup. Building has security at entrance."
  ].sample + " Ref ##{index}"
end

count.times do |i|
  now = Time.current

  package_type = if dataset == "real"
    "#{REAL_PACKAGE_TYPES.sample} (#{SecureRandom.hex(2).upcase})"
  else
    "Demo Package ##{i + 1}"
  end

  start_city = dataset == "real" ? REAL_CITIES.sample : [ "Tel Aviv", "Jerusalem", "Haifa", "Beer Sheva", "Eilat" ].sample
  target_city = dataset == "real" ? (REAL_CITIES - [ start_city ]).sample : [ "Rishon LeZion", "Netanya", "Ashdod", "Herzliya", "Petah Tikva" ].sample
  pickup_address = dataset == "real" ? random_address : [ "Dizengoff St 10, Tel Aviv", "Jaffa St 20, Jerusalem", "HaNassi Blvd 5, Haifa" ].sample
  pickup_notes = dataset == "real" ? real_pickup_notes(i + 1) : "Demo note #{i + 1}"

  delivery_time = if dataset == "real"
    now + rand(2..36).hours
  else
    now + (i + 1).hours
  end

  requested_pickup_time = if dataset == "real"
    now + rand(10..120).minutes
  else
    now + i.minutes
  end

  task = Task.new(
    customer: customer,
    carrier: carrier,
    package_type: package_type,
    start: start_city,
    target: target_city,
    delivery_time: delivery_time,
    filled_form_url: "https://example.com/forms/#{SecureRandom.hex(4)}",
    pickup_address: pickup_address,
    pickup_contact_phone: random_israeli_phone,
    pickup_notes: pickup_notes,
    requested_pickup_time: requested_pickup_time,
    created_by: user,
    status: :postponed,
    published: false,
    priority: Task.priorities.keys.sample
  )

  task.save!
  cart.add_task!(task)
  created << task
end

puts "Created #{created.size} tasks and added to cart for user_id=#{user.id} email=#{user.email}."
puts "Cart now has #{cart.tasks.count} tasks."
