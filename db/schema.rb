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

ActiveRecord::Schema[8.1].define(version: 2026_09_22_013917) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "household_id", null: false
    t.string "icon", default: "tag", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id", "name"], name: "index_categories_on_household_id_and_name", unique: true
    t.index ["household_id"], name: "index_categories_on_household_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.bigint "household_id", null: false
    t.string "memo"
    t.bigint "payer_id", null: false
    t.date "spent_on", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["household_id", "spent_on"], name: "index_expenses_on_household_id_and_spent_on"
    t.index ["household_id"], name: "index_expenses_on_household_id"
    t.index ["payer_id"], name: "index_expenses_on_payer_id"
  end

  create_table "household_members", force: :cascade do |t|
    t.integer "burden_ratio", default: 50, null: false
    t.datetime "created_at", null: false
    t.bigint "household_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["household_id"], name: "index_household_members_on_household_id"
    t.index ["user_id"], name: "index_household_members_on_user_id", unique: true
  end

  create_table "households", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "invite_code"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_code"], name: "index_households_on_invite_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "categories", "households"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "households"
  add_foreign_key "expenses", "users", column: "payer_id"
  add_foreign_key "household_members", "households"
  add_foreign_key "household_members", "users"
end
