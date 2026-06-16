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

ActiveRecord::Schema[7.0].define(version: 2026_06_16_000006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "balances", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "plaid_item_id", null: false
    t.string "plaid_account_id", null: false
    t.string "name"
    t.string "official_name"
    t.string "account_type"
    t.string "account_subtype"
    t.decimal "current_balance", precision: 15, scale: 2
    t.decimal "available_balance", precision: 15, scale: 2
    t.string "iso_currency_code", default: "USD"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plaid_account_id"], name: "index_bank_accounts_on_plaid_account_id", unique: true
    t.index ["plaid_item_id"], name: "index_bank_accounts_on_plaid_item_id"
  end

  create_table "bank_transactions", force: :cascade do |t|
    t.bigint "bank_account_id", null: false
    t.string "plaid_transaction_id", null: false
    t.date "date", null: false
    t.string "name"
    t.string "merchant_name"
    t.decimal "amount", precision: 15, scale: 2
    t.string "category"
    t.string "subcategory"
    t.boolean "pending", default: false
    t.string "iso_currency_code", default: "USD"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_account_id", "date"], name: "index_bank_transactions_on_bank_account_id_and_date"
    t.index ["bank_account_id"], name: "index_bank_transactions_on_bank_account_id"
    t.index ["plaid_transaction_id"], name: "index_bank_transactions_on_plaid_transaction_id", unique: true
  end

  create_table "brokerage_accounts", force: :cascade do |t|
    t.bigint "brokerage_connection_id", null: false
    t.string "snaptrade_account_id", null: false
    t.string "account_name"
    t.string "account_number"
    t.string "account_type"
    t.decimal "cash_balance", precision: 15, scale: 2
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brokerage_connection_id"], name: "index_brokerage_accounts_on_brokerage_connection_id"
  end

  create_table "brokerage_connections", force: :cascade do |t|
    t.string "snaptrade_user_id", null: false
    t.string "snaptrade_auth_token", null: false
    t.string "broker_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "brokerage_positions", force: :cascade do |t|
    t.bigint "brokerage_account_id", null: false
    t.string "symbol", null: false
    t.string "description"
    t.decimal "quantity", precision: 15, scale: 6
    t.decimal "average_purchase_price", precision: 15, scale: 4
    t.decimal "current_price", precision: 15, scale: 4
    t.decimal "current_value", precision: 15, scale: 2
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brokerage_account_id", "symbol"], name: "index_brokerage_positions_on_brokerage_account_id_and_symbol", unique: true
    t.index ["brokerage_account_id"], name: "index_brokerage_positions_on_brokerage_account_id"
  end

  create_table "plaid_items", force: :cascade do |t|
    t.string "plaid_item_id", null: false
    t.string "plaid_access_token", null: false
    t.string "institution_id"
    t.string "institution_name"
    t.string "webhook_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plaid_item_id"], name: "index_plaid_items_on_plaid_item_id", unique: true
  end

  create_table "stock_holdings", force: :cascade do |t|
    t.bigint "stock_id", null: false
    t.decimal "quantity"
    t.decimal "purchase_price"
    t.datetime "purchase_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_stock_holdings_on_stock_id"
  end

  create_table "stocks", force: :cascade do |t|
    t.string "symbol"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "bank_accounts", "plaid_items"
  add_foreign_key "bank_transactions", "bank_accounts"
  add_foreign_key "brokerage_accounts", "brokerage_connections"
  add_foreign_key "brokerage_positions", "brokerage_accounts"
  add_foreign_key "stock_holdings", "stocks"
end
