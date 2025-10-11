# Database Management & CRM Connection Report

## 1. Database Management ✅

### Current Setup
**Database System:** PostgreSQL
**Current Database:** `fast_epost_3_development`
**Total Tables:** 17
**Current Records:**
- Users: 3
- Customers: 2
- Tasks: 2
- Carriers: Present
- Payments: Present

### Database Architecture

#### Multi-Database Configuration
Rails 8 is configured with **4 separate databases** for better performance:

1. **Primary Database** (Main application data)
   - `fast_epost_3_development`
   - All business models: Users, Customers, Tasks, Carriers, Payments, etc.

2. **Cache Database** (Solid Cache)
   - `fast_epost_3_production_cache`
   - High-speed caching layer
   - Migrations: `db/cache_migrate/`

3. **Queue Database** (Solid Queue - Background Jobs)
   - `fast_epost_3_production_queue`
   - Background job processing
   - Migrations: `db/queue_migrate/`

4. **Cable Database** (Solid Cable - WebSockets)
   - `fast_epost_3_production_cable`
   - Real-time WebSocket connections
   - Migrations: `db/cable_migrate/`

### Database Connection Options

#### Development/Test Environment
```yaml
# Option 1: Unix Socket (Default - No password needed)
username: <%= ENV['USER'] || 'codespace' %>

# Option 2: TCP Connection (With DB_HOST environment variable)
host: <%= ENV['DB_HOST'] %>
port: 5432
username: postgres
password: <%= ENV.fetch("DB_PASSWORD", "postgres") %>
```

#### Production Environment
```yaml
# Uses environment variables for security
database: fast_epost_3_production
username: fast_epost_3
password: <%= ENV["FAST_EPOST_3_DATABASE_PASSWORD"] %>
```

### Core Database Tables

#### 1. **users** (Authentication)
- email, encrypted_password
- role (admin/manager/viewer)
- Devise fields (reset_password_token, remember_created_at)

#### 2. **customers** (CRM)
- name, email, address
- phones (text field - array serialization)
- category (integer enum)

#### 3. **carriers**
- carrier_type, name, email, address
- Relations: documents, phones, preferences

#### 4. **tasks** (Main workflow)
- customer_id, carrier_id
- package_type, start, target
- status (0: pending, 1: in_transit, 2: delivered, 3: failed, 4: returned)
- failure_code (enum with prefix)
- barcode (unique), filled_form_url
- delivery_time

#### 5. **payments**
- provider (stripe, local)
- external_id (unique per provider)
- gateway_status (created, pending, succeeded, failed, refunded)
- amount_cents, currency
- Stripe fields: customer_id, payment_intent_id, checkout_session_id, charge_id
- Refund fields: refunded_amount_cents, refund_reason, refund_id

#### 6. **integration_events** (Webhook tracking)
- provider (hubspot, telegram, whatsapp, facebook, instagram, tiktok, websites, stripe)
- headers, body (jsonb)
- signature_valid, status
- external_id (unique per provider)
- processed_at timestamp

#### 7. **refunds**
- payment_id, provider
- refund_id (unique per provider)
- amount_cents, currency, reason
- status, balance_transaction_id
- raw jsonb data

#### Supporting Tables
- **forms**: Dynamic form data (jsonb) with form_template_id
- **form_templates**: Schema definitions (jsonb) for carriers/customers
- **cost_calcs**: Task cost calculations
- **remarks**: Polymorphic notes on tasks
- **payments_tasks**: Many-to-many join table
- **documents**: Carrier ID documents and signatures
- **phones**: Carrier phone numbers (primary flag)
- **preferences**: Carrier settings (bank_account, avatar, background_mode)

### Database Features

#### Indexes
- Unique constraints on emails, barcodes, external IDs
- Composite indexes on provider + external_id
- Foreign key indexes for performance
- Role index for authorization queries

#### Foreign Keys & Cascading
- **CASCADE DELETE**: When parent deleted, children also deleted
  - carrier → documents, phones, preferences
  - task → cost_calcs, remarks, payments
  - payment → refunds, payments_tasks
  - customer → tasks, forms
- **NULLIFY**: Set to null when parent deleted
  - form_template → forms (forms keep data but lose template link)

#### JSONB Fields (PostgreSQL optimized)
- `forms.data` - Dynamic form submissions
- `form_templates.schema` - JSON schema definitions
- `payments.metadata` - Payment context data
- `integration_events.headers` - Webhook headers
- `integration_events.body` - Webhook payloads
- `refunds.raw` - Full refund response data

---

## 2. CRM Connection ✅

### Integrated CRM: HubSpot

#### Setup
**Controller:** `app/controllers/api/v1/integrations/hubspot_controller.rb`
**Service:** `app/services/integrations/hubspot_service.rb`
**Endpoint:** `POST /api/v1/integrations/hubspot`

#### Configuration
```bash
# Environment variables needed
HUBSPOT_APP_SECRET=your_webhook_secret
```

#### Security
- **Webhook Verification**: HMAC SHA-256 signature validation
- **Header**: `X-HubSpot-Signature`
- Validates: `ENV["HUBSPOT_APP_SECRET"]` + request body
- If secret not configured, webhooks are accepted (development mode)

### HubSpot CRM Features

#### 1. **Customer Sync**
Automatically creates/updates customers from HubSpot contacts:

**Mapped Fields:**
- `email` → Customer.email
- `name` → Customer.name  
- `phone` → Customer.phones (appended, deduplicated)

**Smart Matching:**
- Searches by email OR name
- Updates existing customer if found
- Creates new customer if not found

#### 2. **Note/Comment Sync**
Extracts notes from HubSpot webhooks:

**Supported Fields:**
- `note`
- `message`
- `comment`
- `text`

**Behavior:**
- Creates Remark on associated Task
- Links to Customer via polymorphic association
- Stored in `remarks.content`

#### 3. **Event Tracking**
All HubSpot webhooks are logged in `integration_events`:

**Stored Data:**
- Provider: "hubspot"
- Full request headers (jsonb)
- Full payload body (jsonb)
- Signature validation status
- Processing status (received → processed)
- External ID extraction
- Timestamps

**Status Flow:**
1. `received` - Initial webhook capture
2. `processed` - Successfully processed (mark_processed! with true)
3. Error handling - marked processed with false on exception

#### 4. **Task Association**
Uses `Integrations::EventMapper` to link CRM data to tasks:

**Mapping Logic:**
- Searches for task by barcode in payload
- Searches by task_id if provided
- Creates Remark if task found and note present

### CRM Webhook Flow

```
HubSpot → POST /api/v1/integrations/hubspot
    ↓
Verify X-HubSpot-Signature (HMAC)
    ↓
Create integration_event (status: received)
    ↓
Extract customer data (email, name, phone)
    ↓
Upsert Customer (find by email OR name, update/create)
    ↓
Extract note/message/comment
    ↓
Find associated Task (via EventMapper)
    ↓
Create Remark if task + note exists
    ↓
Mark integration_event as processed
    ↓
Return 200 OK
```

### CRM Data Flow

**HubSpot Contact Created/Updated:**
```json
{
  "email": "customer@example.com",
  "properties": {
    "name": "John Doe",
    "phone": "+1-555-0100"
  },
  "note": "Customer requested express delivery"
}
```

**Result:**
1. **Customer Record** (upserted)
   ```ruby
   Customer.create!(
     email: "customer@example.com",
     name: "John Doe",
     phones: "+1-555-0100"
   )
   ```

2. **Remark Record** (if task found)
   ```ruby
   Remark.create!(
     task: task,
     remarkable: customer,
     content: "Customer requested express delivery"
   )
   ```

3. **Integration Event** (logged)
   ```ruby
   IntegrationEvent.create!(
     provider: "hubspot",
     body: { ... },
     status: "processed"
   )
   ```

### Other CRM Integrations Available

#### Platform Support
All configured in `config/routes.rb` under `/api/v1/integrations/`:

1. **Meta Platforms**
   - WhatsApp: GET verify + POST receive
   - Instagram: GET verify + POST receive
   - Facebook: GET verify + POST receive

2. **Social Media**
   - Telegram: POST receive (with secret token)
   - TikTok: POST receive

3. **Generic**
   - Websites: POST receive (custom forms)

4. **CRM**
   - HubSpot: POST receive (documented above)

### Database Management Tools

#### Admin Access
**Monitoring Dashboard:** `/admin/monitoring`
- System statistics
- Database record counts
- Health checks
- Integration event tracking

**Requirements:**
- Admin role (`users.role = 'admin'`)
- Authenticated session

#### Health Checks
**Endpoint:** `GET /admin/monitoring/health`

**Returns:**
```json
{
  "database": {
    "status": "healthy",
    "latency": 12.5
  },
  "cache": {
    "status": "healthy", 
    "latency": 3.2
  },
  "queue": {
    "status": "healthy",
    "pending_jobs": 5
  },
  "stripe": {
    "status": "healthy"
  }
}
```

---

## Database Management Commands

### Migrations
```bash
# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (drop, create, migrate, seed)
bin/rails db:reset

# View migration status
bin/rails db:migrate:status
```

### Seeds
```bash
# Load seed data (creates admin, manager, viewer users)
bin/rails db:seed
```

### Console Access
```bash
# Open Rails console
bin/rails console

# Query database
> User.count
> Customer.all
> Task.includes(:customer, :carrier).first
> IntegrationEvent.where(provider: 'hubspot').count
```

### Backups
```bash
# Dump database
pg_dump -U postgres fast_epost_3_development > backup.sql

# Restore database
psql -U postgres fast_epost_3_development < backup.sql
```

---

## Security & Best Practices

### Database Security
- ✅ Foreign key constraints enforce referential integrity
- ✅ Unique indexes prevent duplicates
- ✅ Cascade deletes maintain consistency
- ✅ Encrypted passwords (Devise bcrypt)
- ✅ Role-based access control

### CRM Security
- ✅ HMAC signature verification for HubSpot
- ✅ All webhook payloads logged in integration_events
- ✅ Signature validation status tracked
- ✅ Rate limiting possible via rack-attack (can be added)

### Data Privacy
- ✅ Sensitive data in environment variables
- ✅ No passwords in source code
- ✅ Structured logging without sensitive fields
- ✅ Admin-only access to monitoring

---

## Current Status Summary

### ✅ Database Management
- Multi-database architecture (primary, cache, queue, cable)
- 17 tables with proper relationships
- JSONB support for flexible data
- Foreign key constraints
- Indexed for performance
- Active: 3 users, 2 customers, 2 tasks

### ✅ CRM Connection (HubSpot)
- Webhook endpoint configured
- Customer auto-sync (email, name, phone)
- Note/comment sync to remarks
- Event logging and tracking
- Signature verification
- Task association

### 🚀 Ready For
- Production deployment
- Additional CRM integrations
- Data migration from other systems
- API consumption by frontend
- Real-time updates via Turbo Streams

---

## Next Steps (Optional Enhancements)

### Database Management
1. Add database backup automation
2. Implement database health monitoring alerts
3. Add query performance monitoring (Bullet gem)
4. Database replication for high availability

### CRM Enhancements
1. Bi-directional sync (push updates back to HubSpot)
2. Add Salesforce integration
3. Custom field mapping configuration UI
4. Webhook retry queue for failed deliveries
5. CRM dashboard in admin panel
6. Contact deduplication tools

### Monitoring
1. Add database query analytics
2. Slow query logging
3. Connection pool monitoring
4. Integration event replay capability

---

**Documentation Generated:** October 10, 2025
**Database:** PostgreSQL (fast_epost_3_development)
**CRM:** HubSpot (Webhook integration)
**Status:** ✅ All systems operational
