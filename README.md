# Fast Epost 3 - Rails Postal Management System

A modern, full-featured postal and courier management system built with Rails 8, featuring a pixel-perfect TailAdmin dashboard, real-time updates with Turbo Streams, and comprehensive payment processing.

![Rails](https://img.shields.io/badge/Rails-8.0.1-red.svg)
![Ruby](https://img.shields.io/badge/Ruby-3.4.1-red.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 🆕 Recent Progress (Dec 2025)

- **Payments & Webhooks Stabilized**: API now allows `Customer` payables for payments and webhooks; fixtures load dependencies deterministically to keep the suite green.
- **PDF Generation Reliability**: Authorization PDFs render without the app layout, and tests stub Grover to avoid local Puppeteer requirements while still validating attachment.
- **Proof Upload Coverage**: Added proof upload fixture and controller test stability for carrier control panel flows.
- **Test Suite Health**: Full suite passes (`bin/rails test`); use it after fixture or payment-related changes.

## ✨ Features

### 🎨 Modern UI/UX
- **TailAdmin Design System**: Pixel-perfect implementation with consistent color palette and components
- **Responsive Layout**: Mobile-first design with adaptive sidebar and navigation
- **Dark Mode Ready**: TailAdmin color tokens with dark mode support
- **Material Icons**: Self-hosted icons for CSP compliance
- **Custom Typography**: Satoshi font family with fallback stack
- **Gradient Flash Notices**: Luxe, dismissible alerts with TailAdmin shadows and RTL-safe layout.
- **Locale-Aware Shell**: Layouts read `localStorage` and locale metadata to set `dir` + `lang` before paint, preventing flicker.

### 📊 Dashboard & Analytics
- **Real-time KPI Cards**: Payments, pending items, revenue tracking, customer counts
- **Interactive Charts**: Monthly sales visualization with Stimulus controllers
- **Recent Activity**: Live updates for tasks, payments, and customers
- **Turbo Streams**: Real-time updates without page refresh

### 💳 Payment Processing
- **Multi-Provider Support**: Stripe, PayPal, and local checkout simulation
- **Payment Lifecycle**: Create, capture, refund, cancel operations
- **Refund History**: Track all refund transactions with status
- **Webhook Integration**: Secure payment provider callbacks
- **Status Tracking**: Visual badges for payment states (succeeded, pending, failed)

### 💸 Carrier Payout Sync
- **Automated Backfill**: `CarrierPayoutSyncJob` derives carrier-facing payouts from every `Payment` whose payable is a carrier, so control panels always show real amounts owed.
- **Rake Task**: Run `bin/rails carrier_payouts:sync` to enqueue the job; add `PURGE=true` to drop any stale rows before rebuilding from payments.
- **Live Updates**: Carrier payouts refresh automatically whenever a carrier payment is created, updated, or removed, keeping dashboards, APIs, and metrics consistent.

### 📦 Task Management
- **Package Tracking**: Monitor shipments from creation to delivery
- **Carrier Integration**: Multiple carrier support (postal, courier)
- **Status Updates**: Pending, in-transit, delivered, failed, returned
- **Delivery Management**: Track delivery times and failure codes
- **Customer Association**: Link tasks to customer profiles
- **Priority Levels**: Normal, urgent, and express priorities drive escalations in the UI, notifications, and mailers

### 👥 Customer Management
- **Comprehensive Profiles**: Contact info, category, address management
- **Category Support**: Individual, business, government classifications
- **Task Overview**: View all customer-related shipments
- **Forms & Templates**: Custom form support per customer

### 🚚 Carrier Management (Admin Only)
- **Carrier CRUD**: Complete management of postal and courier carriers
- **Contact Management**: Email, phone, address tracking
- **Document Storage**: Carrier documentation and signatures
- **Preference Settings**: Carrier-specific configurations

### 📮 Sender Management (Admin Only)
- **Sender Profiles**: Track package originators (individual/business/government)
- **Multi-Type Support**: Personal senders, business clients, government entities
- **Business Details**: Company name, tax ID, business registration
- **Task History**: View all packages sent by each sender
- **Contact Management**: Primary and secondary contact information

### 🚴 Carrier Field Team (Admin Only)
- **Field Personnel**: Track carrier couriers and delivery partners
- **Real-time Status**: Available, busy, offline status tracking
- **Vehicle Management**: Support for van, motorcycle, bicycle, car, truck
- **GPS Tracking**: Current location tracking with JSONB storage
- **Performance Metrics**: Total deliveries, on-time rate
- **Carrier Association**: Link couriers to specific parent carriers
- **Working Hours**: Track carrier field team availability schedules

### 🔔 Notification Orchestration
- **Channel Preferences**: Inline Turbo forms on customer, carrier, and sender dashboards let operators mix email/SMS/in-app per recipient with quiet hours.
- **SMS Delivery**: `SmsDelivery` routes texts through Twilio when `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_PHONE_NUMBER` are set; otherwise the stub keeps local/test runs deterministic.
- **Audit Trail**: Every attempt is logged to `NotificationLog`, so admins can trace why something was sent or skipped.
- **Quiet Hour Enforcement**: `NotificationPreference` automatically suppresses SMS during configured windows without requiring extra business logic.

### 🔗 CRM Integration (Admin Only)
- **Primary: Odoo CRM** - Open source, completely free
  - Contact synchronization via webhooks
  - Lead/opportunity tracking
  - Automated Actions for real-time sync
  - Self-hosted for full data control
- **Alternative: HubSpot CRM** - Available if needed later
  - Free tier support
  - Marketing automation
  - Ready to enable with environment variable
- **CRM Dashboard**: Monitor integrations at `/admin/crm`
- **Event Logging**: Track all webhook calls and sync status
- **Customer Sync**: Automatic creation of Customer records from CRM

### 📱 Social Media Integration
- **Configurable Links**: Dynamic social media icons on landing page
- **WhatsApp Business**: Direct "Chat Now" button integration
- **Multi-Platform**: Facebook, Instagram, Telegram, TikTok webhook support
- **Easy Configuration**: Update URLs in `config/social_media.yml`

### 🔐 Role-Based Access Control
- **Admin Role**: Full system access including carrier management
- **Manager Role**: Payment operations and customer management
- **Viewer Role**: Read-only dashboard access
- **Demo Mode**: Simulate roles via environment variable (`DEMO_ROLE`)
- **Controller Guards**: `require_admin!` and `require_manager!` filters
- **UI Gating**: Sidebar links hidden based on user permissions

### 🎯 Technical Highlights
- **Hotwire Stack**: Turbo + Stimulus for reactive SPA-like experience
- **CSP Compliant**: No external CDNs, all assets self-hosted
- **Solid Suite**: Solid Queue, Solid Cache, Solid Cable for background jobs, caching, and WebSockets
- **Importmap**: Zero-build frontend with native ES modules
- **Rails 8**: Latest framework features and conventions

## 🚀 Getting Started

### Prerequisites

- Ruby 3.4.1 or higher
- PostgreSQL 16
- Node.js (for asset management)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/khalilayoub23/rails_fast_epost.git
   cd rails_fast_epost
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   bin/setup
   ```
   
   This will:
   - Create databases (main, cache, queue, cable)
   - Load schema
   - Seed demo data

4. **Start the development server**
   ```bash
   bin/dev
   ```

5. **Visit the application**
   ```
   http://localhost:3000
   ```

### Configuration

#### Environment Variables

1. Copy the template and adjust values for your environment:

  ```bash
  cp .env.example .env
  ```

2. Update the sections in `.env`:

  - **Core + URLs:** `APP_BASE_URL`, `APP_URL`, `HOST`, log level, and `PORT` control hostnames used in Stripe redirects, Telegram webhooks, etc.
  - **Database:** `DATABASE_HOST`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_URL` should match your local Postgres (defaults target the included docker-compose service).
  - **Email:** `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` drive Action Mailer/NotificationService delivery.
  - **SMS:** `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER` enable SmsDelivery so NotificationService can text carriers/customers and power the dashboard preference UI options.
  - **Payments:** `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET`, and `LOCALPAY_APP_SECRET` are required for checkout flows and webhook verification.
  - **PDF (RTL/Hebrew):** set `PDF_OVERLAY_FONT_PATH` to a Hebrew-capable TTF (for example Noto Sans Hebrew). In production, `PDF_ENFORCE_HEBREW_FONT=true` (default) fails app boot if active RTL templates exist and no font is found.
  - **CRM + Integrations:** `ODOO_API_KEY`, `ODOO_URL`, `HUBSPOT_APP_SECRET`, `WEBSITES_SHARED_SECRET`, `META_VERIFY_TOKEN`, `META_APP_SECRET`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_SECRET_TOKEN`, `TIKTOK_APP_SECRET` secure the webhook controllers.
  - **Demo accounts:** `DEFAULT_*` values seed local admin/manager/viewer logins when `DefaultAccountsProvisioner` runs in development.

Refer to `.env.example` for the full list (job concurrency, PDF determinism toggle, optional HubSpot OAuth keys, etc.).

#### CRM Setup (Odoo - Primary)

See detailed guide: [ODOO_CRM_SETUP.md](ODOO_CRM_SETUP.md)

Quick steps:
1. Generate API key: `openssl rand -hex 32`
2. Add to `.env`: `ODOO_API_KEY=your_key`
3. Configure Odoo Automated Actions to POST to `/api/v1/integrations/odoo`
4. Monitor integration at `/admin/crm`

#### Database Configuration

Edit `config/database.yml` for custom PostgreSQL settings:
- Host, port, username, password
- Connection pooling
- Multiple database support (main, cache, queue, cable)

## 📁 Project Structure

```
app/
├── assets/
│   ├── fonts/              # Self-hosted fonts (Satoshi/Inter)
│   ├── images/             # Application images
│   └── stylesheets/
│       ├── application.css # TailAdmin color tokens and utilities
│       ├── fonts.css       # Font-face declarations
│       └── material-icons.css # Self-hosted Material Icons
├── controllers/
│   ├── application_controller.rb  # Base controller with role helpers
│   ├── dashboard_controller.rb    # KPI and analytics
│   ├── payments_controller.rb     # Payment CRUD + actions
│   ├── customers_controller.rb    # Customer management
│   ├── tasks_controller.rb        # Task tracking
│   └── carriers_controller.rb     # Carrier management (admin only)
├── javascript/
│   ├── application.js      # Hotwire imports
│   └── controllers/
│       ├── dropdown_controller.js      # User menu dropdown
│       ├── sidebar_controller.js       # Mobile sidebar toggle
│       ├── simple_modal_controller.js  # CSP-safe modals
│       ├── charts_controller.js        # Inline SVG charts
│       └── flash_controller.js         # Auto-dismiss alerts
├── models/
│   ├── carrier.rb          # Postal/courier carrier
│   ├── customer.rb         # Customer with enum categories
│   ├── sender.rb           # Package sender (individual/business/government)
│   ├── messenger.rb        # Carrier field courier with GPS tracking
│   ├── task.rb             # Shipment tracking with sender/carrier courier
│   ├── payment.rb          # Payment with refunds
│   └── current.rb          # Current user context
└── views/
    ├── layouts/
    │   └── application.html.erb  # TailAdmin shell
    ├── shared/
    │   ├── _sidebar.html.erb     # Navigation with role gating
    │   ├── _topbar.html.erb      # Header with user menu
    │   ├── _flash.html.erb       # Alert messages
    │   └── _status_badge.html.erb # Status pills
    ├── dashboard/
    │   ├── index.html.erb        # Main dashboard
    │   └── _kpis.html.erb        # KPI cards partial
    ├── payments/               # Payment views
    ├── customers/              # Customer views
    ├── tasks/                  # Task views
    └── carriers/               # Carrier views (admin only)

config/
├── database.yml            # Multi-database configuration
├── routes.rb               # Application routes
├── importmap.rb            # JavaScript dependencies
└── initializers/
    └── db_connection_rescue.rb  # Graceful DB error handling

db/
├── schema.rb               # Database schema
├── seeds.rb                # Demo data seeder
└── migrate/                # Database migrations
```

## 🎨 Styling & Design

### TailAdmin Integration

The application uses a custom TailAdmin implementation with:

**Color Palette**:
- Primary: `#3c50e0` (blue)
- Success: `#219653` (green)
- Danger: `#d34053` (red)
- Warning: `#ffa70b` (orange)
- Body text: `#64748b` (slate)
- Background: `#f1f5f9` (whiten)

**Custom Utilities** (`app/assets/stylesheets/application.css`):
```css
.bg-primary, .text-primary, .border-primary
.bg-whiten, .bg-whiter, .bg-gray-2
.text-dark, .text-body
.border-stroke
.shadow-default, .shadow-card
.text-title-md, .text-title-md2
.badge-success, .badge-warning, .badge-danger
```

**Component Patterns**:
- Cards: `rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default`
- Tables: `w-full table-auto` with `bg-gray-2` headers
- Buttons: `rounded bg-primary px-4 py-2 text-sm font-medium text-white`
- Forms: `rounded border border-stroke focus:border-primary`

### Removed Dependencies

To maintain TailAdmin purity and reduce bundle size (~6 MB saved):
- ❌ DaisyUI (replaced with TailAdmin utilities)
- ❌ Flowbite (replaced with Stimulus controllers)

## 🔧 Development

### Running Tests

```bash
# All tests
bin/rails test

# Specific test file
bin/rails test test/models/payment_test.rb

# System tests (with browser)
bin/rails test:system
```

### Linting

```bash
# RuboCop with rails-omakase style
bin/rubocop

# Auto-fix issues
bin/rubocop -a
```

### Console

```bash
bin/rails console
```

### Database Commands

```bash
# Reset database
bin/rails db:reset

# Run migrations
bin/rails db:migrate

# Seed data
bin/rails db:seed

# View schema
bin/rails db:schema:dump
```

### Priority Column Rollout (Nov 21, 2025)

The `tasks` table now includes a `priority` enum (`normal`, `urgent`, `express`) that powers the updated UI badges and carrier alert emails.

1. Run the migration after pulling:

   ```bash
   bin/rails db:migrate
   ```

2. Existing records default to `normal`. Optionally backfill urgent/express tasks using your own heuristics. Example based on delivery window and pickup notes:

   ```bash
   bin/rails runner <<'RUBY'
   urgent_cutoff = 24.hours.from_now

   Task.where(status: %i[pending in_transit])
     .where('delivery_time <= ?', urgent_cutoff)
     .update_all(priority: :urgent)

   Task.where("pickup_notes ILIKE ?", '%express%')
     .update_all(priority: :express)
   RUBY
   ```

3. Rebuild any cached dashboards so the new priority badges appear immediately (Turbo Stream subscribers update automatically once tasks are touched).

## 🚢 Deployment

### Docker with Kamal

The application is configured for deployment with Kamal:

```bash
# Setup (first time)
kamal setup

# Deploy
kamal deploy

# View logs
kamal app logs
```

### Production Configuration

- **Web Server**: Thruster (HTTP/2 with automatic TLS)
- **App Server**: Puma (multi-threaded)
- **Background Jobs**: Solid Queue
- **WebSockets**: Solid Cable
- **Caching**: Solid Cache
- **PDF Guard**: `config/initializers/pdf_hebrew_font_guard.rb` prevents production boot when RTL templates are active without a Hebrew-capable overlay font.

For PDF overlays, place a Hebrew font in one of these locations (or set `PDF_OVERLAY_FONT_PATH`):
- `app/assets/fonts/NotoSansHebrew-Regular.ttf`
- `vendor/fonts/NotoSansHebrew-Regular.ttf`
- `/usr/share/fonts/truetype/noto/NotoSansHebrew-Regular.ttf`

## 📊 Database Schema

### Core Models

- **Carriers**: Postal and courier service providers
- **Customers**: Individual, business, or government clients
- **Tasks**: Shipment tracking with status workflow
- **Payments**: Multi-provider payment processing with refunds
- **Forms**: Custom forms with JSON schema support
- **Documents**: Carrier documentation storage

### Relationships

```
Customer
  ├── has_many :tasks
  ├── has_many :forms
  └── has_many :form_templates

Task
  ├── belongs_to :customer
  ├── belongs_to :carrier
  ├── has_many :payments (through: payments_tasks)
  ├── has_one :cost_calc
  └── has_many :remarks

Payment
  ├── has_many :refunds (payments with category: refund)
  └── has_many :tasks (through: payments_tasks)

Carrier
  ├── has_many :tasks
  ├── has_many :phones
  ├── has_many :documents
  ├── has_one :preference
  └── has_many :form_templates
```

## 🔐 Security

- **CSRF Protection**: Rails authenticity tokens
- **CSP Headers**: Strict content security policy
- **SQL Injection**: ActiveRecord parameterization
- **XSS Protection**: Automatic HTML escaping
- **Role-Based Access**: Controller-level authorization
- **Secure Headers**: X-Frame-Options, X-Content-Type-Options

## 🚀 Roadmap & Future Enhancements

### Authentication & Authorization

#### 1. **Real User Authentication** 🔐
**Status**: Planned | **Priority**: High

Replace the demo user simulation with a full authentication system:

```bash
# Add Devise gem
bundle add devise

# Generate Devise User model
rails generate devise:install
rails generate devise User
rails generate migration AddRoleToUsers role:string

# Update ApplicationController
# Remove: set_current_user demo method
# Add: Devise helpers (current_user, authenticate_user!)
```

**Implementation Steps**:
- [ ] Install Devise gem
- [ ] Generate User model with email/password
- [ ] Add `role` column (admin, manager, viewer)
- [ ] Migrate `Current.user` to real `current_user` from Devise
- [ ] Update `require_admin!` and `require_manager!` to use real roles
- [ ] Add sign in/sign up/sign out pages with TailAdmin styling
- [ ] Add password reset functionality
- [ ] Add email confirmation (optional)

**Files to Update**:
- `app/models/user.rb` - Add role enum and helper methods
- `app/controllers/application_controller.rb` - Remove demo user, add Devise
- `db/migrate/` - User table with devise and role columns
- `app/views/devise/` - Custom TailAdmin-styled auth pages

#### 2. **Advanced Authorization** 🛡️
**Status**: Planned | **Priority**: Medium

Add granular permission management with CanCanCan or Pundit:

**Option A: CanCanCan (Ability-based)**
```bash
bundle add cancancan

# Generate ability file
rails generate cancan:ability
```

**Option B: Pundit (Policy-based)**
```bash
bundle add pundit

# Generate application policy
rails generate pundit:install
rails generate pundit:policy Payment
rails generate pundit:policy Carrier
```

**Features to Add**:
- [ ] Resource-level permissions (view, create, edit, delete)
- [ ] Custom policies per model (Payment, Task, Carrier, etc.)
- [ ] Policy scopes for index actions
- [ ] Admin-only sections and pages
- [ ] Manager-level delegation
- [ ] Viewer read-only enforcement
- [ ] Permission caching for performance

**Example Policies**:
```ruby
# app/policies/carrier_policy.rb
class CarrierPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager?
  end
  
  def create?
    user.admin?
  end
  
  def destroy?
    user.admin?
  end
end
```

### Design & UX Improvements

#### 3. **Satoshi Font Integration** 🎨
**Status**: Ready | **Priority**: Low

Add authentic Satoshi font files for pixel-perfect TailAdmin typography:

**Steps**:
1. Download Satoshi fonts from [fontshare.com](https://www.fontshare.com/fonts/satoshi)
2. Place files in `app/assets/fonts/`:
   ```
   app/assets/fonts/
   ├── Satoshi-Variable.woff2
   ├── Satoshi-VariableItalic.woff2
   ├── Satoshi-Light.woff2
   ├── Satoshi-Regular.woff2
   ├── Satoshi-Medium.woff2
   ├── Satoshi-Bold.woff2
   └── Satoshi-Black.woff2
   ```
3. Update `app/assets/stylesheets/fonts.css`:
   ```css
   @font-face {
     font-family: "Satoshi";
     src: url("../fonts/Satoshi-Variable.woff2") format("woff2");
     font-weight: 100 900;
     font-style: normal;
     font-display: swap;
   }
   ```

**Current Fallback**: Inter variable fonts (visually similar)

#### 4. **Profile & Settings Pages** ⚙️
**Status**: Placeholder Created | **Priority**: Medium

Create user profile and application settings pages:

**Profile Page** (`/profile`):
- [ ] User information display (name, email, role)
- [ ] Avatar upload with ActiveStorage
- [ ] Personal preferences (timezone, language, notifications)
- [ ] Activity log (recent actions)
- [ ] Two-factor authentication toggle
- [ ] API token generation

**Settings Page** (`/settings`):
- [ ] Application-wide settings (admin only)
- [ ] Email configuration (SMTP settings)
- [ ] Payment gateway configuration (Stripe, PayPal keys)
- [ ] Notification preferences
- [ ] Webhook management
- [ ] System logs viewer
- [ ] Database backup/restore

**File Locations**:
```
app/
├── controllers/
│   ├── profile_controller.rb      # User profile CRUD
│   └── settings_controller.rb     # App settings (admin only)
├── views/
│   ├── profile/
│   │   └── show.html.erb          # Profile page
│   └── settings/
│       └── index.html.erb         # Settings dashboard
└── models/
    ├── user.rb                    # Add profile attributes
    └── setting.rb                 # Key-value settings store
```

**Implementation**:
```bash
# Generate Profile controller
rails generate controller Profile show edit update

# Generate Settings controller
rails generate controller Settings index update

# Generate Settings model for key-value storage
rails generate model Setting key:string value:text description:string
```

#### 5. **Admin Dashboard** 👨‍💼
**Status**: Planned | **Priority**: Medium

Create dedicated admin-only sections:

**Admin Features**:
- [ ] User management (list, create, edit, delete users)
- [ ] Role assignment interface
- [ ] System health monitoring
- [ ] Analytics dashboard (advanced metrics)
- [ ] Audit logs (who did what, when)
- [ ] Background job monitoring (Solid Queue UI)

## Demo data for background jobs

Create sample tasks, payments, and queued jobs for local inspection:

```bash
bin/rails demo:setup
```

What it does:
- Seeds a carrier, customer, sender, messenger, lawyer, and three demo tasks tied to that carrier.
- Creates per-task payments (payable to the carrier) so payouts and KPIs populate.
- Adds a demo delivery record for PDF processing.
- Enqueues `CarrierPayoutSyncJob`, `PaymentsSyncJob`, and `ProcessDeliveryPdfJob` (Solid Queue). Run `bin/jobs` or start the server with `SOLID_QUEUE_IN_PUMA=1` to process them, then view `/admin/monitoring/jobs`.
- [ ] Cache management (Solid Cache UI)
- [ ] Database query analyzer
- [ ] API usage statistics

**Routes**:
```ruby
namespace :admin do
  resources :users
  resources :audit_logs, only: [:index, :show]
  resource :system_health, only: [:show]
  resource :analytics, only: [:show]
end
```

### Feature Expansions

#### 6. **Enhanced Notifications** 🔔
**Status**: In Progress | **Priority**: Medium

- [ ] Real-time in-app notifications with Turbo Streams
- [x] Email notifications for task status changes
- [x] SMS notifications via Twilio (NotificationService + SmsDelivery)
- [ ] Notification preferences UI (backend table `notification_preferences` shipped)
- [ ] Push notifications (PWA)
- [ ] Notification center in topbar

#### 7. **Advanced Reporting** 📊
**Status**: Planned | **Priority**: Low

- [ ] PDF invoice generation
- [ ] Excel export for payments/tasks
- [ ] Custom report builder
- [ ] Scheduled reports (daily/weekly/monthly)
- [ ] Chart.js integration for advanced visualizations
- [ ] Revenue forecasting

#### 8. **API Documentation** 📚
**Status**: Planned | **Priority**: Low

- [ ] Swagger/OpenAPI spec generation
- [ ] Interactive API explorer
- [ ] API rate limiting
- [ ] OAuth 2.0 authentication for API
- [ ] Webhook documentation
- [ ] API versioning (v2, v3, etc.)

#### 9. **Internationalization (i18n)** 🌍
**Status**: In Progress | **Priority**: Medium

- [x] Multi-language support (English, Hebrew, Arabic, Russian) with locale-aware routing + content.
- [x] RTL layout support for Arabic/Hebrew, including persisted `dir` + `lang` state.
- [x] Native `<details>` locale picker with system test coverage (`LocaleSwitcherTest`).
- [x] LocalStorage sync to keep public + dashboard shells in the correct direction pre-paint.
- [ ] Currency localization
- [ ] Date/time format per locale
- [ ] Translatable admin interface

#### 10. **Testing & Quality** ✅
**Status**: In Progress | **Priority**: High

- [ ] Increase test coverage to 90%+
- [ ] Add system tests for critical flows
- [ ] Performance benchmarking
- [ ] Accessibility audit (WCAG 2.1 AA)
- [ ] Security audit with Brakeman
- [ ] Load testing with Apache Bench

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **TailAdmin**: Dashboard design inspiration
- **Rails Team**: Amazing framework and conventions
- **Hotwire**: Modern reactive frontend without complexity
- **Material Icons**: Comprehensive icon library

## 📧 Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/khalilayoub23/rails_fast_epost/issues)
- Email: support@example.com

---

Built with ❤️ using Rails 8 and TailAdmin
