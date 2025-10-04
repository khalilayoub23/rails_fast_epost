# Changelog - Database Schema Updates

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
