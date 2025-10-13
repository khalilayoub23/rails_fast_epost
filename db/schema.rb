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

ActiveRecord::Schema[8.0].define(version: 2025_10_11_125058) do
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

  create_table "carriers", force: :cascade do |t|
    t.string "carrier_type"
    t.string "name"
    t.string "email"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["customer_id"], name: "index_forms_on_customer_id"
    t.index ["form_template_id"], name: "index_forms_on_form_template_id"
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
  end

  create_table "payments", force: :cascade do |t|
    t.integer "category"
    t.bigint "task_id", null: false
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
    t.index ["email"], name: "index_senders_on_email"
    t.index ["sender_type"], name: "index_senders_on_sender_type"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "carrier_id", null: false
    t.string "package_type"
    t.string "start"
    t.string "target"
    t.integer "failure_code"
    t.datetime "delivery_time"
    t.integer "status"
    t.string "barcode"
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
    t.index ["carrier_id"], name: "index_tasks_on_carrier_id"
    t.index ["customer_id"], name: "index_tasks_on_customer_id"
    t.index ["lawyer_id"], name: "index_tasks_on_lawyer_id"
    t.index ["messenger_id"], name: "index_tasks_on_messenger_id"
    t.index ["sender_id"], name: "index_tasks_on_sender_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "viewer", null: false
    t.string "preferred_language"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cost_calcs", "tasks", on_delete: :cascade
  add_foreign_key "documents", "carriers", on_delete: :cascade
  add_foreign_key "form_templates", "carriers", on_delete: :cascade
  add_foreign_key "form_templates", "customers", on_delete: :cascade
  add_foreign_key "forms", "customers", on_delete: :cascade
  add_foreign_key "forms", "form_templates", on_delete: :nullify
  add_foreign_key "messengers", "carriers"
  add_foreign_key "payments", "tasks", on_delete: :cascade
  add_foreign_key "payments_tasks", "payments", on_delete: :cascade
  add_foreign_key "payments_tasks", "tasks", on_delete: :cascade
  add_foreign_key "phones", "carriers", on_delete: :cascade
  add_foreign_key "preferences", "carriers", on_delete: :cascade
  add_foreign_key "refunds", "payments", on_delete: :cascade
  add_foreign_key "remarks", "tasks", on_delete: :cascade
  add_foreign_key "tasks", "carriers", on_delete: :cascade
  add_foreign_key "tasks", "customers", on_delete: :cascade
  add_foreign_key "tasks", "lawyers"
  add_foreign_key "tasks", "messengers"
  add_foreign_key "tasks", "senders"
end
