# PR Changelog

## Summary
This branch hardens task checkout materialization, standardizes task-type POA behavior, improves admin PDF endpoint safety, removes route/config drift, and finishes CSP-safe UI cleanup.

## Backend reliability
- Persist manager-created checkout tasks before Stripe checkout in [app/controllers/tasks_controller.rb](app/controllers/tasks_controller.rb), including:
  - Draft status handling before payment
  - Generated required fields for draft save (`delivery_time`, `barcode`)
  - Snapshot metadata now includes `task_id` for reliable materialization
- Improve enum snapshot normalization in [app/services/task_payment_materializer.rb](app/services/task_payment_materializer.rb) to correctly map enum names and integers.
- Add regression coverage in [test/services/task_payment_materializer_test.rb](test/services/task_payment_materializer_test.rb) for:
  - Existing-task attach by `task_id`
  - Enum-name status normalization

## Task-type / POA consistency
- Centralize mandatory POA task types in [app/models/task.rb](app/models/task.rb) via `POA_MANDATORY_TASK_TYPES`.
- Reuse the same constant in [app/views/tasks/_legal_documents.html.erb](app/views/tasks/_legal_documents.html.erb) to avoid form/model drift.

## PDF/admin hardening
- Add robust upload validation and guarded error responses in [app/controllers/admin/pdfs_controller.rb](app/controllers/admin/pdfs_controller.rb) for merge/stamp/insert/rotate/crop operations.

## Routing and jobs
- Remove duplicate profile route declaration in [config/routes.rb](config/routes.rb).
- Activate recurring sync jobs in [config/recurring.yml](config/recurring.yml):
  - `PaymentsSyncJob` every 10 minutes
  - `CarrierPayoutSyncJob` every hour

## Locale consistency
- Fix Arabic locale key parity for task-card keys in [config/locales/ar.yml](config/locales/ar.yml), resolving i18n consistency test failures.

## UI/CSP cleanup that shipped with branch
- Replace inline-style/onerror patterns with class/controller-based behavior across affected views and styles, including:
  - [app/assets/stylesheets/application.css](app/assets/stylesheets/application.css)
  - [app/javascript/controllers/modal_controller.js](app/javascript/controllers/modal_controller.js)
  - [app/javascript/controllers/image_fallback_controller.js](app/javascript/controllers/image_fallback_controller.js)
  - [app/views/admin/brandings/show.html.erb](app/views/admin/brandings/show.html.erb)
  - [app/views/shared/_footer.html.erb](app/views/shared/_footer.html.erb)
  - [app/views/shared/_brand_bar.html.erb](app/views/shared/_brand_bar.html.erb)

## Validation
- Full tests: `bin/rails test` → 365 runs, 0 failures, 0 errors
- Lint: `bin/rubocop` → no offenses
- Targeted checks that also passed:
  - `bin/rails test test/services/task_payment_materializer_test.rb`
  - `bin/rails test test/controllers/tasks_checkout_flow_test.rb test/controllers/tasks_controller_test.rb`
  - `bin/rails test test/requests/admin_pdfs_test.rb test/requests/pdf_editor_test.rb`
  - `bin/rails routes -g profile`

## Notes
- Removed accidental editor artifact file from this branch and restored placeholder file consistency.
