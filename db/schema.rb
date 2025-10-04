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

ActiveRecord::Schema[8.0].define(version: 2025_09_02_160001) do
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
    t.index ["carrier_id"], name: "index_form_templates_on_carrier_id"
    t.index ["customer_id"], name: "index_form_templates_on_customer_id"
  end

  create_table "forms", force: :cascade do |t|
    t.string "address"
    t.bigint "customer_id", null: false
    t.string "form_default_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_forms_on_customer_id"
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
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable"
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

  add_foreign_key "cost_calcs", "tasks"
  add_foreign_key "documents", "carriers"
  add_foreign_key "form_templates", "carriers"
  add_foreign_key "form_templates", "customers"
  add_foreign_key "forms", "customers"
  add_foreign_key "payments", "tasks"
  add_foreign_key "payments_tasks", "payments"
  add_foreign_key "payments_tasks", "tasks"
  add_foreign_key "phones", "carriers"
  add_foreign_key "preferences", "carriers"
  add_foreign_key "remarks", "tasks"
  add_foreign_key "tasks", "carriers"
  add_foreign_key "tasks", "customers"
end
