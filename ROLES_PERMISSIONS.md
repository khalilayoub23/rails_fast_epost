# Roles & Permissions (Fast Epost 3)

This document summarizes how user roles and permissions are enforced across the app (Pundit policies + controller guards).

## Roles (User model)
Defined in [app/models/user.rb](app/models/user.rb):

- admin
- manager
- operations_manager
- support_agent
- warehouse_agent
- carrier_staff
- carrier
- sender
- lawyer
- ecommerce_seller

Notes:
- `manager?` is true for `manager`, `operations_manager`, and `admin`.
- `carrier_staff?` is true for `carrier_staff` and `carrier`.
- `viewer?` returns true for `sender`, `lawyer`, `ecommerce_seller` and for users without a role but with matching `user_type`.

## Global enforcement
- **Pundit** is used for resource authorization: [app/policies/application_policy.rb](app/policies/application_policy.rb).
- **Controller guards** add high-level restrictions (admin/manager/control panel access).
- Authentication is enforced globally in [app/controllers/application_controller.rb](app/controllers/application_controller.rb).

## Control panel access
Defined in [app/controllers/control_panel/base_controller.rb](app/controllers/control_panel/base_controller.rb):

- **Control panel entry**: admin, operations_manager, or users with carrier memberships.
- **Operations panels**: admin or operations_manager only.

## Pundit policies (core resources)

### Tasks
Policy: [app/policies/task_policy.rb](app/policies/task_policy.rb)

- **index?**: any authenticated user.
- **show?**: admin/manager/support/warehouse OR sender owner OR carrier member OR assigned lawyer.
- **create?**: admin/manager or sender-like roles.
- **update?**:
  - admin/manager: yes
  - warehouse agent: yes
  - assigned lawyer: yes
  - sender owner: only when status is pending
- **destroy?**: admin/manager only.
- **Scope**:
  - admin/manager/support/warehouse: all tasks
  - carrier staff: tasks for their carrier(s)
  - lawyers: tasks where `tasks.lawyer_id` matches their Lawyer profile (email lookup)
  - sender/ecommerce: tasks where `sender_id` matches user id

### Deliveries
Policy: [app/policies/delivery_policy.rb](app/policies/delivery_policy.rb)

- **index?**: manager or any authenticated user.
- **show?**: manager/support/warehouse or participant (sender/courier/recipient).
- **create?**: manager or user types sender/lawyer/ecommerce_seller.
- **update?**: manager or warehouse agent.
- **destroy?**: admin only.
- **sign?**: participant only.
- **Scope**:
  - admin/manager/support/warehouse: all
  - otherwise limited to sender/courier/recipient.

### Payments
Policy: [app/policies/payment_policy.rb](app/policies/payment_policy.rb)

- **index?**: admin/manager or sender-like roles.
- **show?**: admin/manager or sender who owns the payment’s task.
- **create?/update?/destroy?**: admin/manager only.
- **Scope**:
  - admin/manager: all
  - sender-like roles: payments for tasks with `sender_id = current_user.id`

### Refunds
Policy: [app/policies/refund_policy.rb](app/policies/refund_policy.rb)

- **index?**: admin/manager or sender-like roles.
- **show?**: admin/manager or sender-like roles if `PaymentPolicy#show?` allows it.
- **create?/update?/destroy?**: admin/manager only.
- **Scope**: refunds tied to payments visible via `PaymentPolicy`.

### Carrier Payouts
Policy: [app/policies/carrier_payout_policy.rb](app/policies/carrier_payout_policy.rb)

- **index?**: admin/manager or carrier_staff.
- **show?**: admin/manager or carrier_staff where payout matches user’s carrier.
- **Scope**:
  - admin/manager: all
  - carrier staff: payouts for their carriers

### Viewer access
Policy: [app/policies/viewer_policy.rb](app/policies/viewer_policy.rb)

- **access_dashboard?**: `viewer?`
- **view_payments?**: `viewer?`
- **view_tasks?**: `viewer?`
- **Scope**: if a model has `sender_id`, viewers are scoped to their own records.

### User signature updates
Policy: [app/policies/user_policy.rb](app/policies/user_policy.rb)

- **update_signature?**: user can update their own signature; managers can update any.

## Controller-level guards (high level)

- **Admin namespace** (dashboard, monitoring, CRM, branding, senders, etc.): `require_admin!` in each admin controller. See [app/controllers/admin](app/controllers/admin).
- **Payments controller**: `require_manager!` for create/update/destroy/refund/capture/cancel/sync. See [app/controllers/payments_controller.rb](app/controllers/payments_controller.rb).
- **Control panel**: enforced in [app/controllers/control_panel/base_controller.rb](app/controllers/control_panel/base_controller.rb).

## Sender-like roles (common grouping)
Several policies treat these as “sender-like”:
- `sender`, `lawyer`, `ecommerce_seller`

This impacts:
- Task creation
- Payment visibility
- Refund visibility

## Lawyer assignment rule
For tasks, lawyers are authorized by matching the current user’s email to a `Lawyer` profile and comparing `tasks.lawyer_id` to that profile’s id.

---

## Role → Permission Matrix (summary)

Legend: ✅ allowed, ❌ not allowed, ⚠️ conditional

| Capability | Admin | Manager / Ops Manager | Support Agent | Warehouse Agent | Carrier Staff | Sender | Lawyer | Ecommerce Seller |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Dashboard access | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Task: view | ✅ | ✅ | ✅ | ✅ | ⚠️ (carrier tasks) | ⚠️ (own tasks) | ⚠️ (assigned) | ⚠️ (own tasks) |
| Task: create | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Task: update | ✅ | ✅ | ❌ | ✅ | ❌ | ⚠️ (pending only) | ✅ (assigned) | ⚠️ (pending only) |
| Task: delete | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Delivery: view | ✅ | ✅ | ✅ | ✅ | ⚠️ (participant) | ⚠️ (participant) | ⚠️ (participant) | ⚠️ (participant) |
| Delivery: create | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Delivery: update | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Payment: view | ✅ | ✅ | ❌ | ❌ | ❌ | ⚠️ (own) | ⚠️ (own) | ⚠️ (own) |
| Payment: create/update | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Refunds: view | ✅ | ✅ | ❌ | ❌ | ❌ | ⚠️ (own) | ⚠️ (own) | ⚠️ (own) |
| Refunds: create/update | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Carrier payouts: view | ✅ | ✅ | ❌ | ❌ | ⚠️ (carrier only) | ❌ | ❌ | ❌ |
| Control panel (ops) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Control panel (lawyer) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |

## Audit & Fixes Applied

### Audit highlights
1. **Lawyer control panel access blocked**
  - `ControlPanel::Lawyers::DashboardsController` was guarded by `require_operations_role!` and the base control-panel gate, which blocked actual lawyers.
2. **Accessible lawyers scope locked to operations-only**
  - `accessible_lawyers` in `ControlPanel::BaseController` only returned records for operations roles, which prevented lawyers from resolving their own panel context.
3. **Admin controllers missing admin guard**
  - `Admin::LawyersController`, `Admin::ContactInquiriesController`, and `Admin::DocumentTemplatesController` had no `require_admin!` gate.

### Fixes implemented
1. **Lawyer panel access**
  - Lawyers can now access their own control panel panel while operations/admin still retain access.
  - Implemented by skipping the base control-panel gate for the lawyer dashboard and adding a specific `require_lawyer_panel_access!` guard.
  - Implemented in [app/controllers/control_panel/lawyers/dashboards_controller.rb](app/controllers/control_panel/lawyers/dashboards_controller.rb).

2. **Lawyer panel scoping**
  - `accessible_lawyers` is overridden in the lawyer dashboard controller so lawyers only see their own `Lawyer` profile (via email lookup).
  - Admin/ops still see the full list for operational oversight.

3. **Admin controller hardening**
   - Added `require_admin!` to admin controllers that were missing it:
     - [app/controllers/admin/lawyers_controller.rb](app/controllers/admin/lawyers_controller.rb)
     - [app/controllers/admin/contact_inquiries_controller.rb](app/controllers/admin/contact_inquiries_controller.rb)
     - [app/controllers/admin/document_templates_controller.rb](app/controllers/admin/document_templates_controller.rb)

---

## Admin Controllers Audit

All admin controllers now enforce access with either `require_admin!` or `require_admin_or_manager!` (explicitly noted):

- ✅ Admin only (`require_admin!`)
  - [app/controllers/admin/dashboard_controller.rb](app/controllers/admin/dashboard_controller.rb)
  - [app/controllers/admin/monitoring_controller.rb](app/controllers/admin/monitoring_controller.rb)
  - [app/controllers/admin/database_controller.rb](app/controllers/admin/database_controller.rb)
  - [app/controllers/admin/senders_controller.rb](app/controllers/admin/senders_controller.rb)
  - [app/controllers/admin/branding_controller.rb](app/controllers/admin/branding_controller.rb)
  - [app/controllers/admin/brandings_controller.rb](app/controllers/admin/brandings_controller.rb)
  - [app/controllers/admin/crm_controller.rb](app/controllers/admin/crm_controller.rb)
  - [app/controllers/admin/pdfs_controller.rb](app/controllers/admin/pdfs_controller.rb)
  - [app/controllers/admin/dashboard_layouts_controller.rb](app/controllers/admin/dashboard_layouts_controller.rb)
  - [app/controllers/admin/lawyers_controller.rb](app/controllers/admin/lawyers_controller.rb)
  - [app/controllers/admin/contact_inquiries_controller.rb](app/controllers/admin/contact_inquiries_controller.rb)
  - [app/controllers/admin/document_templates_controller.rb](app/controllers/admin/document_templates_controller.rb)

- ⚠️ Admin or Manager (`require_admin_or_manager!`)
  - [app/controllers/admin/messengers_controller.rb](app/controllers/admin/messengers_controller.rb)
  - [app/controllers/admin/messengers/notification_preferences_controller.rb](app/controllers/admin/messengers/notification_preferences_controller.rb)

---

## Policies + Controllers Coverage (summary)

These controllers explicitly authorize with Pundit:

- Deliveries: [app/controllers/deliveries_controller.rb](app/controllers/deliveries_controller.rb)
- Signatures: [app/controllers/signatures_controller.rb](app/controllers/signatures_controller.rb)
- Tasks: [app/controllers/tasks_controller.rb](app/controllers/tasks_controller.rb)
- Dashboard (viewer access): [app/controllers/dashboard_controller.rb](app/controllers/dashboard_controller.rb)
- Users (signature updates): [app/controllers/users_controller.rb](app/controllers/users_controller.rb)

Policies currently defined:

- [app/policies/task_policy.rb](app/policies/task_policy.rb)
- [app/policies/delivery_policy.rb](app/policies/delivery_policy.rb)
- [app/policies/payment_policy.rb](app/policies/payment_policy.rb)
- [app/policies/refund_policy.rb](app/policies/refund_policy.rb)
- [app/policies/carrier_payout_policy.rb](app/policies/carrier_payout_policy.rb)
- [app/policies/viewer_policy.rb](app/policies/viewer_policy.rb)
- [app/policies/user_policy.rb](app/policies/user_policy.rb)
- [app/policies/customer_policy.rb](app/policies/customer_policy.rb)
- [app/policies/carrier_policy.rb](app/policies/carrier_policy.rb)
- [app/policies/document_policy.rb](app/policies/document_policy.rb)
- [app/policies/phone_policy.rb](app/policies/phone_policy.rb)
- [app/policies/preference_policy.rb](app/policies/preference_policy.rb)
- [app/policies/form_template_policy.rb](app/policies/form_template_policy.rb)
- [app/policies/form_policy.rb](app/policies/form_policy.rb)
- [app/policies/remark_policy.rb](app/policies/remark_policy.rb)
- [app/policies/cost_calc_policy.rb](app/policies/cost_calc_policy.rb)
- [app/policies/payments_task_policy.rb](app/policies/payments_task_policy.rb)
- [app/policies/carrier_rating_policy.rb](app/policies/carrier_rating_policy.rb)
- [app/policies/tracking_event_policy.rb](app/policies/tracking_event_policy.rb)

Controllers now explicitly authorize these resources:

- Customers: [app/controllers/customers_controller.rb](app/controllers/customers_controller.rb)
- Carriers: [app/controllers/carriers_controller.rb](app/controllers/carriers_controller.rb)
- Carrier Documents: [app/controllers/documents_controller.rb](app/controllers/documents_controller.rb)
- Carrier Phones: [app/controllers/phones_controller.rb](app/controllers/phones_controller.rb)
- Carrier Preferences: [app/controllers/preferences_controller.rb](app/controllers/preferences_controller.rb)
- Form Templates: [app/controllers/form_templates_controller.rb](app/controllers/form_templates_controller.rb)
- Forms: [app/controllers/forms_controller.rb](app/controllers/forms_controller.rb)
- Remarks: [app/controllers/remarks_controller.rb](app/controllers/remarks_controller.rb)
- Cost Calcs: [app/controllers/cost_calcs_controller.rb](app/controllers/cost_calcs_controller.rb)
- Payments–Tasks linking: [app/controllers/payments_tasks_controller.rb](app/controllers/payments_tasks_controller.rb)
- Carrier Ratings: [app/controllers/carrier_ratings_controller.rb](app/controllers/carrier_ratings_controller.rb)

API controllers now enforce authentication + Pundit where applicable:

- API Tasks: [app/controllers/api/v1/tasks_controller.rb](app/controllers/api/v1/tasks_controller.rb)
- API Customers: [app/controllers/api/v1/customers_controller.rb](app/controllers/api/v1/customers_controller.rb)
- API Carriers: [app/controllers/api/v1/carriers_controller.rb](app/controllers/api/v1/carriers_controller.rb)
- Carrier API Tasks: [app/controllers/api/v1/carriers/tasks_controller.rb](app/controllers/api/v1/carriers/tasks_controller.rb)
- Carrier API Payouts: [app/controllers/api/v1/carriers/payouts_controller.rb](app/controllers/api/v1/carriers/payouts_controller.rb)
- Carrier API Events: [app/controllers/api/v1/carriers/events_controller.rb](app/controllers/api/v1/carriers/events_controller.rb)

Public/Webhook endpoints hardened:

- Public tracking API now requires `PUBLIC_TRACKING_API_KEY` via `X-Public-Api-Key` header: [app/controllers/api/v1/public/tracking_controller.rb](app/controllers/api/v1/public/tracking_controller.rb)
- Websites webhook now requires `WEBSITES_SHARED_SECRET` header match: [app/controllers/api/v1/integrations/websites_controller.rb](app/controllers/api/v1/integrations/websites_controller.rb)
- HubSpot webhook now requires `HUBSPOT_APP_SECRET` HMAC signature: [app/controllers/api/v1/integrations/hubspot_controller.rb](app/controllers/api/v1/integrations/hubspot_controller.rb)
- Payments webhook now requires provider secrets:
  - Local: `LOCALPAY_APP_SECRET` with `X-Localpay-Secret` header
  - Stripe: `STRIPE_WEBHOOK_SECRET` configured
  - See [app/controllers/api/v1/payments_controller.rb](app/controllers/api/v1/payments_controller.rb)
- Payment intents webhook now requires `LOCALPAY_APP_SECRET` with `X-Localpay-Secret` header:
  - [app/controllers/api/v1/payments/payment_intents_controller.rb](app/controllers/api/v1/payments/payment_intents_controller.rb)
- Meta webhooks (Facebook/Instagram/WhatsApp) now require `META_VERIFY_TOKEN` for verify and `META_APP_SECRET` for POST signatures:
  - [app/controllers/api/v1/integrations/facebook_controller.rb](app/controllers/api/v1/integrations/facebook_controller.rb)
  - [app/controllers/api/v1/integrations/instagram_controller.rb](app/controllers/api/v1/integrations/instagram_controller.rb)
  - [app/controllers/api/v1/integrations/whatsapp_controller.rb](app/controllers/api/v1/integrations/whatsapp_controller.rb)
- Telegram webhook requires `TELEGRAM_SECRET_TOKEN` header match:
  - [app/controllers/api/v1/integrations/telegram_controller.rb](app/controllers/api/v1/integrations/telegram_controller.rb)
- TikTok webhook requires `TIKTOK_APP_SECRET` signature:
  - [app/controllers/api/v1/integrations/tiktok_controller.rb](app/controllers/api/v1/integrations/tiktok_controller.rb)
- Odoo webhook requires `ODOO_API_KEY` via `X-Odoo-Api-Key`:
  - [app/controllers/api/v1/integrations/odoo_controller.rb](app/controllers/api/v1/integrations/odoo_controller.rb)

If you want a full audit of every controller + policy pairing or a stricter ruleset, say the scope and I’ll extend it.
