# Sender & Messenger Implementation - Complete

**Date**: October 10, 2025  
**Status**: ✅ Database & Models Complete | 🔄 UI Pending  
**Migrations**: 3 migrations applied successfully

---

## 🎯 What Was Implemented

### 1. **Sender Model** 📦
Complete model for tracking who SENDS packages (not just who receives them).

**Database Table: `senders`**
```ruby
- name: string (required) - Sender's name
- email: string (required, unique) - Contact email
- phone: string (required) - Primary phone
- address: text (required) - Full address
- sender_type: integer (enum) - individual(0), business(1), government(2)

# Business-specific fields
- company_name: string - Company name for business/government
- tax_id: string - Tax identification
- business_registration: string - Business registration number

# Additional contact
- secondary_phone: string - Alternate phone
- website: string - Company website

# Data storage
- preferences: jsonb - Sender preferences
- notes: text - Internal notes
```

**Model Features**:
- ✅ Enum for sender types (individual/business/government)
- ✅ Validations (required fields, email format, uniqueness)
- ✅ Business validations (company_name required for businesses)
- ✅ Has many tasks relationship
- ✅ Scopes (individuals, businesses, governments, recent, active)
- ✅ Helper methods (display_name, full_contact_info, total_shipments)

**Use Cases**:
1. **B2B Shipping**: Company A (sender) ships to Company B (customer)
2. **Returns**: Customer becomes sender, company becomes recipient
3. **International Customs**: Need sender details for declarations
4. **Legal Documents**: Power of attorney needs sender information
5. **Pickup Requests**: Need sender's address for pickup location

---

### 2. **Messenger Model** 🚚
Complete model for tracking individual delivery personnel (the actual person delivering packages).

**Database Table: `messengers`**
```ruby
- name: string (required) - Messenger's name
- email: string - Contact email
- phone: string (required) - Primary phone
- carrier_id: references (optional) - Which company they work for

# Status tracking
- status: integer (enum, default: 0) - available(0), busy(1), offline(2)

# Vehicle information
- vehicle_type: integer (enum) - van(0), motorcycle(1), bicycle(2), car(3), truck(4)
- license_plate: string - Vehicle license plate

# Credentials
- license_number: string - Driver's license
- employee_id: string (unique) - Company employee ID

# Performance metrics
- total_deliveries: integer (default: 0) - Total completed deliveries
- on_time_rate: float (default: 0.0) - Percentage of on-time deliveries

# Location & scheduling
- current_location: jsonb - {lat, lng, updated_at}
- working_hours: jsonb - {monday: "9-17", tuesday: "9-17", ...}
- notes: text - Internal notes
```

**Model Features**:
- ✅ Enum for status (available/busy/offline)
- ✅ Enum for vehicle types (van/motorcycle/bicycle/car/truck)
- ✅ Validations (required fields, uniqueness, numeric ranges)
- ✅ Belongs to carrier (optional - can be independent)
- ✅ Has many tasks
- ✅ Scopes (available, busy, offline, for_carrier, top_performers, with_vehicle)
- ✅ Location tracking (update_location method)
- ✅ Performance calculation (calculate_on_time_rate)
- ✅ Status management (mark_busy!, mark_available!, mark_offline!)
- ✅ Working hours check (working_today?)

**Use Cases**:
1. **Task Assignment**: Assign delivery to specific person (John Smith, not just "FedEx")
2. **Real-Time Tracking**: See where delivery person is on map
3. **Performance Management**: Track individual delivery success rates
4. **Capacity Planning**: Know who's available vs busy vs offline
5. **Customer Experience**: "John Smith arriving in 10 minutes" notifications
6. **Workload Balancing**: Distribute tasks evenly among messengers

---

### 3. **Task Model Updates** 📋
Updated existing Task model to support both senders and messengers.

**New Fields Added to `tasks` table**:
```ruby
- sender_id: references (optional) - Who sends the package
- messenger_id: references (optional) - Who delivers the package

# Pickup details (from sender location)
- pickup_address: text - Where to pick up from
- pickup_contact_phone: string - Contact at pickup location
- pickup_notes: text - Special pickup instructions
- requested_pickup_time: datetime - When sender wants pickup
```

**Updated Relationships**:
```ruby
class Task < ApplicationRecord
  belongs_to :customer          # Who RECEIVES (existing)
  belongs_to :carrier           # Company handling it (existing)
  belongs_to :sender, optional: true    # Who SENDS (NEW)
  belongs_to :messenger, optional: true # Who delivers it (NEW)
end
```

**Complete Task Flow**:
```
Sender → Carrier → Messenger → Customer
  ↓         ↓          ↓           ↓
John Doe  FedEx  John Smith  Jane Corp
(Person) (Company) (Person)   (Company)
```

---

## 📊 Database Schema

### Senders Table
```sql
CREATE TABLE senders (
  id bigserial PRIMARY KEY,
  name varchar NOT NULL,
  email varchar NOT NULL UNIQUE,
  phone varchar NOT NULL,
  address text NOT NULL,
  sender_type integer DEFAULT 0 NOT NULL,
  company_name varchar,
  tax_id varchar,
  business_registration varchar,
  secondary_phone varchar,
  website varchar,
  preferences jsonb DEFAULT '{}',
  notes text,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL
);

CREATE INDEX index_senders_on_email ON senders(email);
CREATE INDEX index_senders_on_sender_type ON senders(sender_type);
CREATE INDEX index_senders_on_company_name ON senders(company_name);
```

### Messengers Table
```sql
CREATE TABLE messengers (
  id bigserial PRIMARY KEY,
  name varchar NOT NULL,
  email varchar,
  phone varchar NOT NULL,
  status integer DEFAULT 0 NOT NULL,
  vehicle_type integer,
  license_plate varchar,
  license_number varchar,
  employee_id varchar UNIQUE,
  total_deliveries integer DEFAULT 0,
  on_time_rate float DEFAULT 0.0,
  current_location jsonb DEFAULT '{}',
  working_hours jsonb DEFAULT '{}',
  carrier_id bigint REFERENCES carriers(id),
  notes text,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL
);

CREATE INDEX index_messengers_on_status ON messengers(status);
CREATE INDEX index_messengers_on_carrier_id ON messengers(carrier_id);
CREATE INDEX index_messengers_on_employee_id ON messengers(employee_id);
```

### Tasks Table (Updated)
```sql
ALTER TABLE tasks ADD COLUMN sender_id bigint REFERENCES senders(id);
ALTER TABLE tasks ADD COLUMN messenger_id bigint REFERENCES messengers(id);
ALTER TABLE tasks ADD COLUMN pickup_address text;
ALTER TABLE tasks ADD COLUMN pickup_contact_phone varchar;
ALTER TABLE tasks ADD COLUMN pickup_notes text;
ALTER TABLE tasks ADD COLUMN requested_pickup_time timestamp;

CREATE INDEX index_tasks_on_sender_id ON tasks(sender_id);
CREATE INDEX index_tasks_on_messenger_id ON tasks(messenger_id);
```

---

## 🎨 Example Usage

### Creating a Sender
```ruby
# Individual sender
sender = Sender.create!(
  name: "John Doe",
  email: "john@example.com",
  phone: "+1-555-0100",
  address: "123 Main St, City, State 12345",
  sender_type: :individual
)

# Business sender
business_sender = Sender.create!(
  name: "Jane Smith",
  email: "jane@acmecorp.com",
  phone: "+1-555-0200",
  address: "456 Corporate Blvd, Business Park",
  sender_type: :business,
  company_name: "Acme Corporation",
  tax_id: "12-3456789",
  business_registration: "BN123456",
  website: "https://acme.com"
)
```

### Creating a Messenger
```ruby
messenger = Messenger.create!(
  name: "Bob Johnson",
  email: "bob@fedex.com",
  phone: "+1-555-0300",
  carrier: Carrier.find_by(name: "FedEx Express"),
  status: :available,
  vehicle_type: :van,
  license_plate: "ABC-1234",
  license_number: "D1234567",
  employee_id: "FX-12345"
)

# Update location
messenger.update_location(40.7128, -74.0060)  # New York coordinates
```

### Creating a Task with Sender & Messenger
```ruby
task = Task.create!(
  customer: Customer.find(1),        # Who receives
  sender: Sender.find(2),            # Who sends
  carrier: Carrier.find_by(name: "FedEx"),
  messenger: Messenger.find(3),      # Who delivers
  
  # Package details
  package_type: "Document",
  start: "New York, NY",
  target: "Boston, MA",
  delivery_time: 2.days.from_now,
  barcode: "FX#{SecureRandom.hex(8)}",
  
  # Pickup details
  pickup_address: sender.address,
  pickup_contact_phone: sender.phone,
  pickup_notes: "Ring bell twice",
  requested_pickup_time: 1.hour.from_now,
  
  status: :pending
)
```

### Task Assignment Workflow
```ruby
# 1. Find available messengers near pickup location
available_messengers = Messenger.available
                               .for_carrier(task.carrier_id)

# 2. Assign to best messenger
messenger = available_messengers.first
task.update(messenger: messenger)
messenger.mark_busy!

# 3. Start delivery
task.ship!  # Status: pending → in_transit

# 4. Complete delivery
task.deliver!  # Status: in_transit → delivered
messenger.update_performance_metrics
messenger.mark_available!
```

### Performance Tracking
```ruby
# Top performing messengers
top_5 = Messenger.top_performers.limit(5)
top_5.each do |m|
  puts "#{m.name}: #{m.on_time_rate}% on-time (#{m.total_deliveries} deliveries)"
end

# Available messengers for assignment
Messenger.available.count  # How many can take tasks right now?

# Sender shipping history
sender = Sender.find(5)
puts "Total shipments: #{sender.total_shipments}"
sender.recent_shipments(10).each do |task|
  puts "Task ##{task.id}: #{task.status} - to #{task.customer.name}"
end
```

---

## 🔄 What's Next (Pending Tasks)

### Phase 1: Admin CRUD Interfaces (Next Priority)

#### 1. Sender Management UI
**File**: `app/controllers/admin/senders_controller.rb`
```ruby
class Admin::SendersController < ApplicationController
  before_action :require_admin!
  
  def index
    @senders = Sender.includes(:tasks).order(created_at: :desc)
                     .page(params[:page])
  end
  
  def new
    @sender = Sender.new
  end
  
  def create
    @sender = Sender.new(sender_params)
    if @sender.save
      redirect_to admin_senders_path, notice: "Sender created successfully"
    else
      render :new
    end
  end
  
  # ... show, edit, update, destroy
end
```

**Views**:
- `app/views/admin/senders/index.html.erb` - List all senders with filters
- `app/views/admin/senders/_form.html.erb` - Sender form (shared)
- `app/views/admin/senders/show.html.erb` - Sender profile with shipment history

#### 2. Messenger Management UI
**File**: `app/controllers/admin/messengers_controller.rb`
```ruby
class Admin::MessengersController < ApplicationController
  before_action :require_admin!
  
  def index
    @messengers = Messenger.includes(:carrier, :tasks).order(created_at: :desc)
    @available_count = Messenger.available.count
    @busy_count = Messenger.busy.count
  end
  
  def performance_dashboard
    @top_performers = Messenger.top_performers.limit(10)
    @low_performers = Messenger.where("on_time_rate < 90").order(on_time_rate: :asc)
  end
  
  # ... CRUD actions
end
```

**Views**:
- `app/views/admin/messengers/index.html.erb` - List with status badges
- `app/views/admin/messengers/performance_dashboard.html.erb` - Performance metrics
- `app/views/admin/messengers/_form.html.erb` - Messenger form
- `app/views/admin/messengers/show.html.erb` - Profile with active tasks

#### 3. Update Task Forms
**Add sender and messenger fields to task creation/editing**:
- Dropdown to select sender (or create new)
- Dropdown to select messenger (filtered by carrier and availability)
- Pickup details form section

---

### Phase 2: Integration with Existing Features

#### 1. Update Task State Machine Notifications
```ruby
# app/models/task.rb
def notify_customer_shipped
  # Existing customer notification
  TaskMailer.shipped_notification(self).deliver_later
  
  # NEW: Notify sender
  TaskMailer.pickup_complete_notification(self, sender).deliver_later if sender.present?
  
  # NEW: Notify messenger
  TaskMailer.delivery_assignment_notification(self, messenger).deliver_later if messenger.present?
end
```

#### 2. Update Dashboard Stats
```ruby
# app/controllers/dashboard_controller.rb
def index
  @stats = {
    # ... existing stats
    available_messengers: Messenger.available.count,
    busy_messengers: Messenger.busy.count,
    top_sender: Sender.joins(:tasks).group(:sender_id).count.max_by { |k, v| v },
    pending_pickups: Task.where(status: :pending).where.not(requested_pickup_time: nil).count
  }
end
```

#### 3. Add to Monitoring Dashboard
- Active messenger count
- Messenger utilization rate (busy / total)
- Top senders by volume
- Pickup requests needing assignment

---

### Phase 3: Advanced Features (Optional)

#### 1. Messenger Mobile App Integration
- API endpoints for messengers to update location
- Task list API for assigned deliveries
- Status update endpoints (picked up, delivered)

#### 2. Sender Portal
- Allow senders to create shipment requests
- Track their sent packages
- Manage preferences

#### 3. Real-Time Location Tracking
- WebSocket integration for live messenger location
- Customer can see messenger approaching on map
- ETA calculation based on distance

#### 4. Automated Task Assignment
- Algorithm to assign tasks to nearest available messenger
- Consider messenger's current location, vehicle type, capacity
- Load balancing across messengers

---

## 📝 Testing Recommendations

### 1. Unit Tests

**Sender Model**:
```ruby
# test/models/sender_test.rb
test "business sender requires company_name" do
  sender = Sender.new(sender_type: :business, ...)
  assert_not sender.valid?
  assert_includes sender.errors[:company_name], "can't be blank"
end
```

**Messenger Model**:
```ruby
# test/models/messenger_test.rb
test "calculate on_time_rate correctly" do
  messenger = messengers(:john)
  rate = messenger.calculate_on_time_rate
  assert_equal 95.5, rate
end
```

### 2. Integration Tests

**Task Assignment**:
```ruby
# test/integration/task_assignment_test.rb
test "assign task to available messenger and update status" do
  task = tasks(:pending_task)
  messenger = messengers(:available_messenger)
  
  task.update(messenger: messenger)
  messenger.reload
  
  assert_equal :busy, messenger.status
end
```

### 3. System Tests

**Sender CRUD**:
```ruby
# test/system/admin/senders_test.rb
test "admin creates new sender" do
  visit new_admin_sender_path
  fill_in "Name", with: "Test Sender"
  fill_in "Email", with: "test@example.com"
  click_button "Create Sender"
  
  assert_text "Sender created successfully"
end
```

---

## 🎯 Summary

### What Works Now ✅
- ✅ Sender model with full validation and relationships
- ✅ Messenger model with status tracking and performance metrics
- ✅ Task model updated with sender and messenger relationships
- ✅ Pickup details stored on tasks
- ✅ Database migrations applied successfully
- ✅ Model associations configured
- ✅ Scopes and helper methods implemented

### What's Missing ❌
- ❌ Admin UI for senders (CRUD interface)
- ❌ Admin UI for messengers (CRUD interface)
- ❌ Task form updates (add sender/messenger dropdowns)
- ❌ Dashboard integration (show messenger status)
- ❌ Notification updates (notify senders and messengers)
- ❌ Test fixtures (senders.yml, messengers.yml)
- ❌ Performance dashboard for messengers
- ❌ Sender portal for shipment requests

###Real-World Benefit 💡
**Before**:
```ruby
task.carrier  # "FedEx" (just the company)
task.customer # Jane Corp (who receives)
# Missing: Who sends? Who actually delivers?
```

**After**:
```ruby
task.sender    # John Doe (who sends the package)
task.carrier   # FedEx (company handling it)
task.messenger # Bob Johnson (FedEx driver delivering it)
task.customer  # Jane Corp (who receives)

# Complete chain of custody!
```

This enables:
- 📦 **Better tracking**: Know exactly who handles each step
- 📞 **Better communication**: Direct contact with sender and delivery person
- 📊 **Better analytics**: Sender volume, messenger performance
- 🔒 **Better accountability**: Clear responsibility at each step
- 🎯 **Better customer service**: "Bob from FedEx is 5 minutes away"

---

**Implementation Status**: 40% Complete  
**Next Step**: Create admin CRUD interfaces for Sender and Messenger management  
**Estimated Time**: 2-3 hours for complete UI implementation
