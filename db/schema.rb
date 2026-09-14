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

ActiveRecord::Schema[8.1].define(version: 2026_01_01_000008) do
  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "category_name", limit: 30, null: false
    t.integer "display_order", null: false
    t.boolean "enabled", default: true, null: false
    t.index ["category_name"], name: "index_categories_on_category_name", unique: true
  end

  create_table "claims", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "category_id", null: false
    t.bigint "claimant_id", null: false
    t.datetime "created_at", null: false
    t.string "description", limit: 100, null: false
    t.date "expense_date", null: false
    t.bigint "pair_id", null: false
    t.bigint "recipient_id", null: false
    t.string "rejection_reason", limit: 100
    t.datetime "responded_at"
    t.string "status", limit: 20, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_claims_on_category_id"
    t.index ["claimant_id"], name: "fk_rails_6309d26880"
    t.index ["expense_date"], name: "index_claims_on_expense_date"
    t.index ["pair_id"], name: "index_claims_on_pair_id"
    t.index ["recipient_id"], name: "fk_rails_305fee828f"
    t.index ["status"], name: "index_claims_on_status"
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message", null: false
    t.string "notification_type", limit: 30, null: false
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.bigint "related_claim_id"
    t.bigint "related_settlement_id"
    t.string "title", limit: 100, null: false
    t.bigint "user_id", null: false
    t.index ["read"], name: "index_notifications_on_read"
    t.index ["related_claim_id"], name: "fk_rails_5cd692d141"
    t.index ["related_settlement_id"], name: "fk_rails_e5f40cd483"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pair_invitations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "invitation_code", limit: 20, null: false
    t.bigint "issued_by", null: false
    t.bigint "pair_id", null: false
    t.string "status", limit: 20, null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "used_by"
    t.index ["invitation_code"], name: "index_pair_invitations_on_invitation_code", unique: true
    t.index ["issued_by"], name: "fk_rails_b7fdb1a40f"
    t.index ["pair_id"], name: "index_pair_invitations_on_pair_id"
    t.index ["used_by"], name: "fk_rails_96a126aebb"
  end

  create_table "pair_members", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "joined_at", null: false
    t.bigint "pair_id", null: false
    t.bigint "user_id", null: false
    t.index ["pair_id", "user_id"], name: "index_pair_members_on_pair_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_pair_members_on_user_id", unique: true
  end

  create_table "pairs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by", null: false
    t.string "pair_name", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["created_by"], name: "fk_rails_d9a098137a"
  end

  create_table "settlements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "approved_by"
    t.integer "approved_claim_count", null: false
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "pair_id", null: false
    t.integer "partner_receivable_total", null: false
    t.bigint "payee_id"
    t.bigint "payer_id"
    t.integer "payment_amount", null: false
    t.datetime "requested_at", null: false
    t.bigint "requested_by", null: false
    t.integer "requester_receivable_total", null: false
    t.date "settlement_month", null: false
    t.string "status", limit: 30, null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by"], name: "fk_rails_5adb7923af"
    t.index ["pair_id", "settlement_month"], name: "index_settlements_on_pair_id_and_settlement_month"
    t.index ["pair_id"], name: "index_settlements_on_pair_id"
    t.index ["payee_id"], name: "fk_rails_25073b27d8"
    t.index ["payer_id"], name: "fk_rails_623cbd4285"
    t.index ["requested_by"], name: "fk_rails_c6ac8c8c76"
    t.index ["status"], name: "index_settlements_on_status"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", limit: 50, null: false
    t.string "email", null: false
    t.boolean "enabled", default: true, null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "claims", "categories"
  add_foreign_key "claims", "pairs"
  add_foreign_key "claims", "users", column: "claimant_id"
  add_foreign_key "claims", "users", column: "recipient_id"
  add_foreign_key "notifications", "claims", column: "related_claim_id"
  add_foreign_key "notifications", "settlements", column: "related_settlement_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "pair_invitations", "pairs"
  add_foreign_key "pair_invitations", "users", column: "issued_by"
  add_foreign_key "pair_invitations", "users", column: "used_by"
  add_foreign_key "pair_members", "pairs"
  add_foreign_key "pair_members", "users"
  add_foreign_key "pairs", "users", column: "created_by"
  add_foreign_key "settlements", "pairs"
  add_foreign_key "settlements", "users", column: "approved_by"
  add_foreign_key "settlements", "users", column: "payee_id"
  add_foreign_key "settlements", "users", column: "payer_id"
  add_foreign_key "settlements", "users", column: "requested_by"
end
