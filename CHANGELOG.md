# Changelog - Database Schema Updates

## [2025-11-21] - Task Priority Rollout

### Added
- `priority` string enum on `Task` (`normal`, `urgent`, `express`) with database index so operators can flag rush deliveries.
- Documentation in `README.md` and `NOTIFICATION_SYSTEM.md` describing how to run the migration plus optional backfill scripts that derive urgency from delivery windows or pickup notes.

### Notes
- After pulling, run `bin/rails db:migrate` followed by any backfill script that marks urgent/express shipments for your tenant data before verifying the messenger alert emails.

## [2025-11-20] - Notification Preference UI & Tests

### Added
- Shallow-nested notification preference controllers for customers, messengers, and senders plus shared Turbo-friendly partials so operators can manage channel opt-ins inline on each dashboard.
- Controller test suites that cover CRUD flows, duplicate channel handling, and admin/manager authorization for messenger/sender scopes.
- Documentation updates (README, NOTIFICATION_SYSTEM.md, GAP reports) outlining how to access the UI, configure Twilio, and audit notification logs.

### Changed
- Customer, admin messenger, and admin sender show pages now embed preference lists/forms in Turbo frames so changes reflect immediately without navigation.
- `config/routes.rb` exposes the new shallow routes while keeping admin guardrails for messenger/sender parents.

## [2025-11-18] - Respondable & Notification Hardening

### Added
- `.env.example` template with grouped sections for Rails, database, SMTP, Stripe/LocalPay, CRM/webhook secrets, and demo account credentials to streamline onboarding.
- Regression tests for `NotificationService` covering email-skipping scenarios (messenger/sender without email, bulk alerts, etc.).
- `notification_preferences` (per-recipient channel opt-ins + quiet hours) and `notification_logs` (auditable delivery history) tables with associated models.
- `SmsDelivery` service plus Twilio initializer so NotificationService can send SMS when `TWILIO_*` env vars are present.

### Changed
- `Respondable#respond_with_update` now accepts explicit `attributes:` arguments so parameter evaluation is separated from Turbo rendering. All controllers invoking it were updated to pass `attributes` and keep Turbo stream blocks dedicated to rendering.
- `NotificationService` now routes both email and SMS through preference-aware helpers, logs every attempt to `notification_logs`, and skips SMS automatically during quiet hours.

### Notes
- Run `DATABASE_USER=postgres DATABASE_PASSWORD=postgres bin/rails test` (seed `42136`, 247 tests) after pulling to ensure local environments mirror CI settings.
- Copy `.env.example` to `.env` and adjust as needed before running `bin/dev` or tests.

## [2025-10-04] - Payments Refunds Audit Trail and UI/API

### Added
- Refund model and migration with fields: provider, refund_id, amount_cents, currency, reason, status, balance_transaction_id, raw (JSONB), occurred_at
- Persistence of refunds from Stripe webhooks (charge.refunded, charge.refund.updated) with idempotency guards
- Management endpoints wiring for refund/capture/cancel/sync and background sync job for pending payments
- PaymentSerializer now includes refunds array and total_refunded_cents
- UI: Refunds history panel on payment show and Total Refunded summary

### Changed
- Consolidated Stripe lifecycle handling in StripeGateway (create, webhook verification, sync, capture, cancel, refund)
- Deterministic PDF rendering enforced in tests/dev for stable outputs
- RuboCop autocorrect for consistent style (no functional changes)

### Notes
- Ensure STRIPE_WEBHOOK_SECRET and STRIPE_API_KEY are set in environment
- Run database migrations: bin/rails db:migrate

## [2025-09-02] - Database Schema Enhancements

### Added
- **New Migration**: `20250902160001_add_number_to_phones.rb`
  - Added `number` field to phones table to store phone numbers

### Enhanced Models with Enums

#### Customer Model (`app/models/customer.rb`)
- Added `category` enum with values: individual (0), business (1), government (2)
- Implemented serialized `phones` array attribute
- Updated validations to work with enum

#### Task Model (`app/models/task.rb`)
- Added `failure_code` enum with values:
  - no_failure (0)
  - address_not_found (1)
  - recipient_unavailable (2)
  - package_damaged (3)
  - refused_delivery (4)
- Added `status` enum with values:
  - pending (0)
  - in_transit (1)
  - delivered (2)
  - failed (3)
  - returned (4)
- Updated validations to work with enums

#### Payment Model (`app/models/payment.rb`)
- Added `category` enum with values: service_fee (0), delivery_fee (1), insurance (2), penalty (3)
- Added `payment_type` enum with values: per_task (0), lump_sum (1)
- Made interval fields nullable for lump_sum payments
- Updated validations

#### Preference Model (`app/models/preference.rb`)
- Added `background_mode` enum with values: light (0), dark (1), auto (2)
- Implemented serialized `bank_account` hash attribute
- Updated validations

#### Phone Model (`app/models/phone.rb`)
- Added validation for `number` field presence

### Documentation
- **Created**: `AGENTS.md` - Agent guidelines with commands, architecture, and code style
- **Created**: `db/schema_summary.md` - Comprehensive database schema documentation

### Database Relationships Validated
- All table connections properly established according to schema diagram
- STI (Single Table Inheritance) for Carriers
- Polymorphic associations for Payments and Remarks
- Many-to-many relationship between Tasks and Payments via PaymentsTasks
- All foreign key constraints and validations in place

### Technical Improvements
- Proper enum usage throughout the system
- Serialized attributes for complex data structures
- Enhanced model validations
- Complete association mappings matching the database schema diagram

### Notes
- All changes maintain backward compatibility
- Database migration required: `bin/rails db:migrate`
- Models now fully match the provided database schema diagram
