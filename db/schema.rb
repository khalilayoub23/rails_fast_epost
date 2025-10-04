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

ActiveRecord::Schema[8.0].define(version: 2025_10_05_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["carrier_id"], name: "index_tasks_on_carrier_id"
    t.index ["customer_id"], name: "index_tasks_on_customer_id"
  end

  add_foreign_key "cost_calcs", "tasks", on_delete: :cascade
  add_foreign_key "documents", "carriers", on_delete: :cascade
  add_foreign_key "form_templates", "carriers", on_delete: :cascade
  add_foreign_key "form_templates", "customers", on_delete: :cascade
  add_foreign_key "forms", "customers", on_delete: :cascade
  add_foreign_key "forms", "form_templates", on_delete: :nullify
  add_foreign_key "payments", "tasks", on_delete: :cascade
  add_foreign_key "payments_tasks", "payments", on_delete: :cascade
  add_foreign_key "payments_tasks", "tasks", on_delete: :cascade
  add_foreign_key "phones", "carriers", on_delete: :cascade
  add_foreign_key "preferences", "carriers", on_delete: :cascade
  add_foreign_key "refunds", "payments", on_delete: :cascade
  add_foreign_key "remarks", "tasks", on_delete: :cascade
  add_foreign_key "tasks", "carriers", on_delete: :cascade
  add_foreign_key "tasks", "customers", on_delete: :cascade
end
