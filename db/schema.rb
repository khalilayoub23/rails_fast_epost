# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_23_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "delivery_id", null: false
    t.bigint "user_id"
    t.string "action", null: false
    t.string "role"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["delivery_id"], name: "index_audit_logs_on_delivery_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "carrier_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "carrier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrier_id"], name: "index_carrier_memberships_on_carrier_id"
    t.index ["user_id", "carrier_id"], name: "index_carrier_memberships_on_user_id_and_carrier_id", unique: true
    t.index ["user_id"], name: "index_carrier_memberships_on_user_id"
  end

  create_table "carrier_payouts", force: :cascade do |t|
    t.bigint "carrier_id", null: false
    t.bigint "task_id", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.string "status", default: "pending", null: false
    t.datetime "due_at"
    t.datetime "paid_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrier_id", "task_id"], name: "index_carrier_payouts_on_carrier_id_and_task_id", unique: true
    t.index ["carrier_id"], name: "index_carrier_payouts_on_carrier_id"
    t.index ["status"], name: "index_carrier_payouts_on_status"
    t.index ["task_id"], name: "index_carrier_payouts_on_task_id"
  end

  create_table "carrier_ratings", force: :cascade do |t|
    t.bigint "carrier_id", null: false
    t.bigint "task_id", null: false
    t.integer "completion_score", null: false
    t.integer "recipient_score", null: false
    t.string "rated_by"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sender_score", default: 3, null: false
    t.index ["carrier_id"], name: "index_carrier_ratings_on_carrier_id"
    t.index ["task_id"], name: "index_carrier_ratings_on_task_id", unique: true
  end

  create_table "carriers", force: :cascade do |t|
    t.string "carrier_type"
    t.string "name"
    t.string "email"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "average_completion_rating", precision: 4, scale: 2, default: "0.0", null: false
    t.decimal "average_service_rating", precision: 4, scale: 2, default: "0.0", null: false
    t.integer "ratings_count", default: 0, null: false
    t.decimal "average_overall_rating", precision: 4, scale: 2, default: "0.0", null: false
    t.decimal "average_sender_rating", precision: 4, scale: 2, default: "0.0", null: false
  end

  create_table "contact_inquiries", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "service"
    t.text "message"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "admin_notes"
  end

  create_table "cost_calcs", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_cost_calcs_on_task_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.text "phones"
    t.integer "category"
    t.string "address"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "bulk_discount", precision: 5, scale: 2
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["name"], name: "index_customers_on_name"
  end

  create_table "deliveries", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.bigint "recipient_id", null: false
    t.bigint "courier_id", null: false
    t.string "case_number", null: false
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.jsonb "signature_data", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "authorization_generated_at"
    t.index ["case_number"], name: "index_deliveries_on_case_number", unique: true
    t.index ["completed_at"], name: "index_deliveries_on_completed_at"
    t.index ["courier_id"], name: "index_deliveries_on_courier_id"
    t.index ["recipient_id"], name: "index_deliveries_on_recipient_id"
    t.index ["sender_id"], name: "index_deliveries_on_sender_id"
    t.index ["signature_data"], name: "index_deliveries_on_signature_data", using: :gin
    t.index ["status"], name: "index_deliveries_on_status"
  end

  create_table "document_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "template_type", default: 0, null: false
    t.string "category"
    t.jsonb "variables", default: {}
    t.boolean "active", default: true
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_document_templates_on_active"
    t.index ["category"], name: "index_document_templates_on_category"
    t.index ["name"], name: "index_document_templates_on_name"
    t.index ["template_type"], name: "index_document_templates_on_template_type"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "carrier_id", null: false
    t.string "id_document"
    t.string "signature"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrier_id"], name: "index_documents_on_carrier_id"
  end

  create_table "form_templates", force: :cascade do |t|
    t.bigint "carrier_id", null: false
    t.bigint "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "schema", default: {}, null: false
    t.index ["carrier_id"], name: "index_form_templates_on_carrier_id"
    t.index ["customer_id"], name: "index_form_templates_on_customer_id"
  end

  create_table "forms", force: :cascade do |t|
    t.string "address"
    t.bigint "customer_id", null: false
    t.string "form_default_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "data", default: {}, null: false
    t.bigint "form_template_id"
    t.bigint "task_id"
    t.index ["customer_id"], name: "index_forms_on_customer_id"
    t.index ["form_template_id"], name: "index_forms_on_form_template_id"
    t.index ["task_id"], name: "index_forms_on_task_id"
  end

  create_table "integration_events", force: :cascade do |t|
    t.string "provider", null: false
    t.jsonb "headers", default: {}, null: false
    t.jsonb "body", default: {}, null: false
    t.boolean "signature_valid", default: false, null: false
    t.string "status", default: "received", null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index ["provider", "created_at"], name: "index_integration_events_on_provider_and_created_at"
    t.index ["provider", "external_id"], name: "index_integration_events_on_provider_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
  end

  create_table "lawyers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.string "license_number", null: false
    t.integer "specialization", default: 0, null: false
    t.string "bar_association"
    t.jsonb "certifications", default: {}
    t.text "notes"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_lawyers_on_active"
    t.index ["email"], name: "index_lawyers_on_email", unique: true
    t.index ["license_number"], name: "index_lawyers_on_license_number", unique: true
    t.index ["specialization"], name: "index_lawyers_on_specialization"
  end

  create_table "messengers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "phone", null: false
    t.integer "status", default: 0, null: false
    t.integer "vehicle_type"
    t.string "license_plate"
    t.string "license_number"
    t.string "employee_id"
    t.integer "total_deliveries", default: 0
    t.float "on_time_rate", default: 0.0
    t.jsonb "current_location", default: {}
    t.jsonb "working_hours", default: {}
    t.bigint "carrier_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrier_id"], name: "index_messengers_on_carrier_id"
    t.index ["employee_id"], name: "index_messengers_on_employee_id"
    t.index ["status"], name: "index_messengers_on_status"
    t.index ["vehicle_type"], name: "index_messengers_on_vehicle_type"
  end

  create_table "notification_logs", force: :cascade do |t|
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.integer "channel", null: false
    t.string "message_type", null: false
    t.string "status", default: "sent", null: false
    t.string "provider_message_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_notification_logs_on_channel"
    t.index ["message_type"], name: "index_notification_logs_on_message_type"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notification_logs_on_notifiable_type_and_notifiable_id"
    t.index ["status"], name: "index_notification_logs_on_status"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.integer "channel", default: 0, null: false
    t.boolean "enabled", default: true, null: false
    t.integer "quiet_hours_start"
    t.integer "quiet_hours_end"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id", "channel"], name: "index_notification_preferences_on_notifiable_and_channel"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "category"
    t.bigint "task_id"
    t.string "payable_type", null: false
    t.bigint "payable_id", null: false
    t.integer "payment_type"
    t.date "interval_start"
    t.date "interval_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "external_id"
    t.string "gateway_status", default: "created", null: false
    t.integer "amount_cents"
    t.string "currency", default: "USD"
    t.string "payment_url"
    t.jsonb "metadata", default: {}, null: false
    t.string "stripe_customer_id"
    t.string "payment_intent_id"
    t.string "checkout_session_id"
    t.string "charge_id"
    t.integer "refunded_amount_cents"
    t.string "refund_reason"
    t.string "refund_id"
    t.string "refund_status"
    t.string "refund_balance_transaction_id"
    t.datetime "refunded_at"
    t.index ["charge_id"], name: "index_payments_on_charge_id"
    t.index ["checkout_session_id"], name: "index_payments_on_checkout_session_id"
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable"
    t.index ["payment_intent_id"], name: "index_payments_on_payment_intent_id"
    t.index ["provider", "external_id"], name: "index_payments_on_provider_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["refund_id"], name: "index_payments_on_refund_id"
    t.index ["task_id"], name: "index_payments_on_task_id"
  end

  create_table "payments_tasks", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "payment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_payments_tasks_on_payment_id"
    t.index ["task_id"], name: "index_payments_tasks_on_task_id"
  end

  create_table "phones", force: :cascade do |t|
    t.bigint "carrier_id", null: false
    t.boolean "primary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number"
    t.index ["carrier_id"], name: "index_phones_on_carrier_id"
  end

  create_table "preferences", force: :cascade do |t|
    t.bigint "carrier_id", null: false
    t.text "bank_account"
    t.string "avatar"
    t.integer "background_mode"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrier_id"], name: "index_preferences_on_carrier_id"
  end

  create_table "proof_uploads", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "carrier_id", null: false
    t.bigint "uploaded_by_id", null: false
    t.string "category", default: "photo", null: false
    t.text "notes"
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrier_id"], name: "index_proof_uploads_on_carrier_id"
    t.index ["category"], name: "index_proof_uploads_on_category"
    t.index ["task_id"], name: "index_proof_uploads_on_task_id"
    t.index ["uploaded_by_id"], name: "index_proof_uploads_on_uploaded_by_id"
  end

  create_table "refunds", force: :cascade do |t|
    t.bigint "payment_id", null: false
    t.string "provider", null: false
    t.string "refund_id"
    t.integer "amount_cents"
    t.string "currency"
    t.string "reason"
    t.string "status"
    t.string "balance_transaction_id"
    t.jsonb "raw", default: {}, null: false
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_refunds_on_payment_id"
    t.index ["provider", "refund_id"], name: "index_refunds_on_provider_and_refund_id", unique: true, where: "(refund_id IS NOT NULL)"
  end

  create_table "remarks", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.string "remarkable_type", null: false
    t.bigint "remarkable_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["remarkable_type", "remarkable_id"], name: "index_remarks_on_remarkable"
    t.index ["task_id"], name: "index_remarks_on_task_id"
  end

  create_table "senders", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.text "address", null: false
    t.integer "sender_type", default: 0, null: false
    t.string "company_name"
    t.string "tax_id"
    t.string "business_registration"
    t.string "secondary_phone"
    t.string "website"
    t.jsonb "preferences", default: {}
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_senders_on_company_name"
    t.index ["email"], name: "index_senders_on_email", unique: true
    t.index ["sender_type"], name: "index_senders_on_sender_type"
  end

  create_table "signature_events", force: :cascade do |t|
    t.bigint "delivery_id", null: false
    t.bigint "user_id", null: false
    t.string "role", null: false
    t.integer "action", default: 0, null: false
    t.string "signature_hash"
    t.string "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_signature_events_on_created_at"
    t.index ["delivery_id", "role"], name: "index_signature_events_on_delivery_id_and_role"
    t.index ["delivery_id"], name: "index_signature_events_on_delivery_id"
    t.index ["signature_hash"], name: "index_signature_events_on_signature_hash"
    t.index ["user_id"], name: "index_signature_events_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "carrier_id", null: false
    t.string "package_type"
    t.string "start"
    t.string "target"
    t.integer "failure_code"
    t.datetime "delivery_time"
    t.integer "status", default: 0, null: false
    t.string "barcode", null: false
    t.string "filled_form_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "sender_id"
    t.bigint "messenger_id"
    t.text "pickup_address"
    t.string "pickup_contact_phone"
    t.text "pickup_notes"
    t.datetime "requested_pickup_time"
    t.bigint "lawyer_id"
    t.string "priority", default: "normal", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.text "last_failure_note"
    t.datetime "stored_until"
    t.boolean "awaiting_customer_response", default: false, null: false
    t.boolean "door_affix_authorized", default: false, null: false
    t.boolean "door_affix_completed", default: false, null: false
    t.datetime "door_affix_completed_at"
    t.decimal "last_success_lat", precision: 10, scale: 6
    t.decimal "last_success_lng", precision: 10, scale: 6
    t.decimal "last_success_accuracy", precision: 8, scale: 2
    t.bigint "created_by_id"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.decimal "distance", precision: 10, scale: 2
    t.integer "task_type", default: 1, null: false
    t.index ["barcode"], name: "index_tasks_on_barcode", unique: true
    t.index ["carrier_id"], name: "index_tasks_on_carrier_id"
    t.index ["created_at"], name: "index_tasks_on_created_at"
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
    t.index ["customer_id"], name: "index_tasks_on_customer_id"
    t.index ["distance"], name: "index_tasks_on_distance"
    t.index ["lawyer_id"], name: "index_tasks_on_lawyer_id"
    t.index ["messenger_id"], name: "index_tasks_on_messenger_id"
    t.index ["priority"], name: "index_tasks_on_priority"
    t.index ["published"], name: "index_tasks_on_published"
    t.index ["sender_id"], name: "index_tasks_on_sender_id"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["task_type"], name: "index_tasks_on_task_type"
  end

  create_table "tracking_events", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.string "event_type", null: false
    t.string "title", null: false
    t.string "status"
    t.string "location"
    t.text "description"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_tracking_events_on_status"
    t.index ["task_id", "occurred_at"], name: "index_tracking_events_on_task_id_and_occurred_at"
    t.index ["task_id"], name: "index_tracking_events_on_task_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "sender", null: false
    t.string "preferred_language"
    t.string "provider"
    t.string "uid"
    t.string "full_name"
    t.string "phone"
    t.text "address"
    t.integer "user_type", null: false, comment: "0=sender,1=lawyer,2=courier,3=recipient"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["user_type"], name: "index_users_on_user_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "deliveries"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "carrier_memberships", "carriers"
  add_foreign_key "carrier_memberships", "users"
  add_foreign_key "carrier_payouts", "carriers"
  add_foreign_key "carrier_payouts", "tasks"
  add_foreign_key "carrier_ratings", "carriers"
  add_foreign_key "carrier_ratings", "tasks"
  add_foreign_key "cost_calcs", "tasks", on_delete: :cascade
  add_foreign_key "deliveries", "users", column: "courier_id"
  add_foreign_key "deliveries", "users", column: "recipient_id"
  add_foreign_key "deliveries", "users", column: "sender_id"
  add_foreign_key "documents", "carriers", on_delete: :cascade
  add_foreign_key "form_templates", "carriers", on_delete: :cascade
  add_foreign_key "form_templates", "customers", on_delete: :cascade
  add_foreign_key "forms", "customers", on_delete: :cascade
  add_foreign_key "forms", "form_templates", on_delete: :nullify
  add_foreign_key "forms", "tasks"
  add_foreign_key "messengers", "carriers"
  add_foreign_key "payments", "tasks", on_delete: :cascade
  add_foreign_key "payments_tasks", "payments", on_delete: :cascade
  add_foreign_key "payments_tasks", "tasks", on_delete: :cascade
  add_foreign_key "phones", "carriers", on_delete: :cascade
  add_foreign_key "preferences", "carriers", on_delete: :cascade
  add_foreign_key "proof_uploads", "carriers"
  add_foreign_key "proof_uploads", "tasks"
  add_foreign_key "proof_uploads", "users", column: "uploaded_by_id"
  add_foreign_key "refunds", "payments", on_delete: :cascade
  add_foreign_key "remarks", "tasks", on_delete: :cascade
  add_foreign_key "signature_events", "deliveries"
  add_foreign_key "signature_events", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "tasks", "carriers", on_delete: :cascade
  add_foreign_key "tasks", "customers", on_delete: :cascade
  add_foreign_key "tasks", "lawyers"
  add_foreign_key "tasks", "messengers"
  add_foreign_key "tasks", "senders"
  add_foreign_key "tasks", "users", column: "created_by_id"
  add_foreign_key "tracking_events", "tasks", on_delete: :cascade
end
