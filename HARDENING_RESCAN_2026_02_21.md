# Hardening Rescan Backlog — 2026-02-21

Scope: routes, controllers, and gateway signature/auth logic reviewed after recent hardening passes.

## High-Priority Findings

### 1) Legacy payment intents controller uses unsafe direct compare ✅ Completed (2026-02-21)
- File: `app/controllers/api/v1/payments/payment_intents_controller.rb`
- Issue: direct `ActiveSupport::SecurityUtils.secure_compare(local_secret, header_secret)` without length guard can raise on mismatched lengths.
- Risk: request-triggered exception path / inconsistent auth behavior.
- Completed:
  - Added length-safe compare helper in controller.
  - Invalid or malformed secret headers now return deterministic `403`.
  - Added focused regression tests for compare behavior.

### 2) Legacy payment intents controller is not routed (orphaned controller) ✅ Completed (2026-02-21)
- File: `app/controllers/api/v1/payments/payment_intents_controller.rb`
- Observation: no matching route in `config/routes.rb`.
- Risk: stale/orphaned security code drifts from active standards.
- Completed:
  - Removed unused/unrouted `app/controllers/api/v1/payments/payment_intents_controller.rb`.
  - Removed associated controller test file.

### 3) Checkout cancel endpoint mutates state on GET ✅ Completed (2026-02-21)
- Route: `get "/checkout/cancel", to: "checkout#cancel"`
- Files: `config/routes.rb`, `app/controllers/checkout_controller.rb`
- Issue: cancellation side-effect is performed via GET.
- Risk: accidental activation via prefetch/crawlers or token leakage scenarios.
- Completed:
  - `GET /checkout/cancel` is now read-only.
  - Added `POST /checkout/cancel/confirm` for state mutation.
  - Token verification is preserved for cancellation.

## Medium-Priority Findings

### 4) API base controller defaults to unauthenticated ✅ Completed (2026-02-21)
- File: `app/controllers/api/v1/base_controller.rb`
- Issue: `skip_before_action :authenticate_user!` at base level.
- Risk: new API controllers may accidentally ship unauthenticated.
- Completed:
  - Removed `skip_before_action :authenticate_user!` from `app/controllers/api/v1/base_controller.rb`.
  - API controllers inheriting from this base now require authentication by default.

### 5) Environment template mismatch in docs ✅ Completed (2026-02-21)
- Files: `README.md` references `.env.example`; verified present in repo.
- Completed:
  - Confirmed `.env.example` exists and matches setup instructions.

## Verification Commands Used During Rescan

```bash
grep/route scan for auth skip + webhook routes
secure_compare pattern scan in controllers
file search for .env.example/.env.template
```

## Current State

All items from this rescan backlog are completed.
