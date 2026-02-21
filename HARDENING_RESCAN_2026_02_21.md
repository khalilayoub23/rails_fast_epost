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

### 2) Legacy payment intents controller is not routed (orphaned controller)
- File: `app/controllers/api/v1/payments/payment_intents_controller.rb`
- Observation: no matching route in `config/routes.rb`.
- Risk: stale/orphaned security code drifts from active standards.
- Action (choose one):
  - Remove controller if truly unused, or
  - Add explicit routes and align auth/validation behavior with `Api::V1::PaymentsController`.

### 3) Checkout cancel endpoint mutates state on GET
- Route: `get "/checkout/cancel", to: "checkout#cancel"`
- Files: `config/routes.rb`, `app/controllers/checkout_controller.rb`
- Issue: cancellation side-effect is performed via GET.
- Risk: accidental activation via prefetch/crawlers or token leakage scenarios.
- Action:
  - Prefer POST/DELETE for state change.
  - Keep token verification, and add replay/expiry guard for cancel token where practical.

## Medium-Priority Findings

### 4) API base controller defaults to unauthenticated
- File: `app/controllers/api/v1/base_controller.rb`
- Issue: `skip_before_action :authenticate_user!` at base level.
- Risk: new API controllers may accidentally ship unauthenticated.
- Action:
  - Invert default to authenticated and explicitly opt-out for public namespaces (`public`, `integrations`, provider webhooks).

### 5) Environment template mismatch in docs
- Files: `README.md` references `.env.example`; template file missing.
- Risk: inconsistent setup and missing required secret inventory for local/CI onboarding.
- Action:
  - Add `.env.example` (recommended) or update docs to reference actual template source.

## Verification Commands Used During Rescan

```bash
grep/route scan for auth skip + webhook routes
secure_compare pattern scan in controllers
file search for .env.example/.env.template
```

## Recommended Next Execution Order

1. Harden `payment_intents_controller` compare logic and behavior.
2. Resolve routed-vs-unused status for `payment_intents_controller`.
3. Convert checkout cancel from GET to non-GET mutation route.
4. Tighten API base auth default.
5. Restore `.env.example` (or adjust docs if intentionally absent).
