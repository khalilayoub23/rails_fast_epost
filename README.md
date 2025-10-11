# Fast Epost 3 - Rails Postal Management System

A modern, full-featured postal and courier management system built with Rails 8, featuring a pixel-perfect TailAdmin dashboard, real-time updates with Turbo Streams, and comprehensive payment processing.

![Rails](https://img.shields.io/badge/Rails-8.0.1-red.svg)
![Ruby](https://img.shields.io/badge/Ruby-3.4.1-red.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### 🎨 Modern UI/UX
- **TailAdmin Design System**: Pixel-perfect implementation with consistent color palette and components
- **Responsive Layout**: Mobile-first design with adaptive sidebar and navigation
- **Dark Mode Ready**: TailAdmin color tokens with dark mode support
- **Material Icons**: Self-hosted icons for CSP compliance
- **Custom Typography**: Satoshi font family with fallback stack

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

### 📦 Task Management
- **Package Tracking**: Monitor shipments from creation to delivery
- **Carrier Integration**: Multiple carrier support (postal, courier)
- **Status Updates**: Pending, in-transit, delivered, failed, returned
- **Delivery Management**: Track delivery times and failure codes
- **Customer Association**: Link tasks to customer profiles

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

### 🚴 Messenger Management (Admin Only)
- **Delivery Personnel**: Track messengers/delivery persons
- **Real-time Status**: Available, busy, offline status tracking
- **Vehicle Management**: Support for van, motorcycle, bicycle, car, truck
- **GPS Tracking**: Current location tracking with JSONB storage
- **Performance Metrics**: Total deliveries, on-time rate
- **Carrier Association**: Link messengers to specific carriers
- **Working Hours**: Track messenger availability schedules

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

```bash
# Database
DB_HOST=127.0.0.1
DB_PASSWORD=password

# Role Simulation (for demo purposes)
DEMO_ROLE=ADMIN  # Options: ADMIN, MANAGER, VIEWER

# Admin Actions (bypass role checks)
ENABLE_ADMIN_ACTIONS=false
```

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
│   ├── messenger.rb        # Delivery personnel with GPS tracking
│   ├── task.rb             # Shipment tracking with sender/messenger
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
**Status**: Planned | **Priority**: Medium

- [ ] Real-time in-app notifications with Turbo Streams
- [ ] Email notifications for task status changes
- [ ] SMS notifications via Twilio
- [ ] Notification preferences per user
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
**Status**: Planned | **Priority**: Low

- [ ] Multi-language support (English, Hebrew, Arabic, French)
- [ ] RTL layout support for Arabic/Hebrew
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
