# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160727080712) do

  create_table "accounting_dates", :force => true do |t|
    t.date     "accounting_date"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.datetime "purge_at"
  end

  add_index "accounting_dates", ["accounting_date"], :name => "index_accounting_dates_on_accounting_date", :unique => true

  create_table "audit_logs", :force => true do |t|
    t.string   "audit_target"
    t.string   "action_type"
    t.string   "action"
    t.string   "action_status"
    t.string   "action_error"
    t.string   "ip"
    t.string   "action_by"
    t.string   "description"
    t.string   "session_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.datetime "action_at"
  end

  create_table "casinos", :force => true do |t|
    t.string   "name",        :limit => 45, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.datetime "purge_at"
    t.integer  "licensee_id"
  end

  create_table "casinos_shift_types", :force => true do |t|
    t.integer  "casino_id",     :null => false
    t.integer  "shift_type_id", :null => false
    t.integer  "sequence",      :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.datetime "purge_at"
  end

  add_index "casinos_shift_types", ["casino_id"], :name => "fk_properties_shift_types_casino_id"
  add_index "casinos_shift_types", ["shift_type_id"], :name => "fk_properties_shift_types_shift_type_id"

  create_table "change_histories", :force => true do |t|
    t.string   "action_by",     :limit => 45, :null => false
    t.string   "object",        :limit => 45, :null => false
    t.string   "action",        :limit => 45, :null => false
    t.string   "change_detail",               :null => false
    t.integer  "licensee_id",                 :null => false
    t.datetime "action_at",                   :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "casino_id"
  end

  add_index "change_histories", ["licensee_id"], :name => "fk_change_histories_licensee_id"

  create_table "configurations", :force => true do |t|
    t.integer  "casino_id",                 :null => false
    t.string   "key",         :limit => 45, :null => false
    t.string   "value",       :limit => 45, :null => false
    t.string   "description", :limit => 45
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "configurations", ["casino_id", "key"], :name => "index_configurations_on_property_id_and_key", :unique => true

  create_table "currencies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "purge_at"
  end

  create_table "kiosk_transactions", :force => true do |t|
    t.integer  "shift_id",                          :null => false
    t.integer  "player_id",                         :null => false
    t.integer  "transaction_type_id",               :null => false
    t.string   "ref_trans_id",        :limit => 45
    t.integer  "amount",              :limit => 8
    t.string   "status",              :limit => 45
    t.datetime "trans_date"
    t.integer  "casino_id",                         :null => false
    t.string   "kiosk_name",          :limit => 45
    t.string   "source_type",         :limit => 45
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "kiosk_transactions", ["casino_id"], :name => "fk_kiosk_casino_id"
  add_index "kiosk_transactions", ["player_id"], :name => "fk_kiosk_player_id"
  add_index "kiosk_transactions", ["shift_id"], :name => "fk_kiosk_shift_id"
  add_index "kiosk_transactions", ["transaction_type_id"], :name => "fk_kiosk_transaction_type_id"

  create_table "licensees", :force => true do |t|
    t.string   "name"
    t.datetime "purge_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "lock_types", :force => true do |t|
    t.string   "name",       :limit => 45, :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.datetime "purge_at"
  end

  create_table "player_transactions", :force => true do |t|
    t.integer  "shift_id"
    t.integer  "player_id"
    t.integer  "user_id"
    t.integer  "transaction_type_id"
    t.string   "status"
    t.integer  "amount",              :limit => 8
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.string   "ref_trans_id",        :limit => 45
    t.datetime "trans_date"
    t.datetime "purge_at"
    t.integer  "casino_id",                         :null => false
    t.integer  "slip_number"
    t.string   "machine_token"
    t.string   "data"
  end

  add_index "player_transactions", ["casino_id"], :name => "fk_player_transactions_casino_id"
  add_index "player_transactions", ["player_id"], :name => "fk_player_id"
  add_index "player_transactions", ["shift_id"], :name => "fk_shift_id"
  add_index "player_transactions", ["transaction_type_id"], :name => "fk_transaction_type_id"
  add_index "player_transactions", ["user_id"], :name => "fk_playerTransaction_user_id"

  create_table "players", :force => true do |t|
    t.string   "member_id"
    t.string   "card_id"
    t.integer  "currency_id"
    t.string   "status"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "purge_at"
    t.integer  "licensee_id",                         :null => false
    t.boolean  "test_mode_player", :default => false, :null => false
  end

  add_index "players", ["card_id", "licensee_id"], :name => "index_players_on_card_id_and_property_id", :unique => true
  add_index "players", ["currency_id"], :name => "fk_currency_id"
  add_index "players", ["licensee_id"], :name => "fk_players_licensee_id"
  add_index "players", ["member_id", "licensee_id"], :name => "index_players_on_member_id_and_property_id", :unique => true

  create_table "players_lock_types", :force => true do |t|
    t.integer  "player_id",                  :null => false
    t.integer  "lock_type_id",               :null => false
    t.string   "status",       :limit => 45, :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.datetime "purge_at"
  end

  add_index "players_lock_types", ["lock_type_id"], :name => "fk_players_lock_types_lock_type_id"
  add_index "players_lock_types", ["player_id", "lock_type_id"], :name => "players_lock_types_player_id_lock_type_id", :unique => true

  create_table "properties", :force => true do |t|
    t.string   "name",       :limit => 45, :null => false
    t.string   "secret_key", :limit => 45, :null => false
    t.datetime "purge_at"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.integer  "casino_id"
  end

  create_table "shift_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "purge_at"
  end

  create_table "shifts", :force => true do |t|
    t.integer  "shift_type_id"
    t.integer  "roll_shift_by_user_id"
    t.datetime "roll_shift_at"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.integer  "accounting_date_id"
    t.integer  "lock_version"
    t.datetime "purge_at"
    t.integer  "casino_id",             :null => false
    t.string   "machine_token"
  end

  add_index "shifts", ["accounting_date_id"], :name => "fk_accounting_date_id"
  add_index "shifts", ["casino_id"], :name => "fk_shifts_casino_id"
  add_index "shifts", ["roll_shift_by_user_id"], :name => "fk_user_id"
  add_index "shifts", ["shift_type_id"], :name => "fk_shift_type_id"

  create_table "slip_types", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "purge_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "tokens", :force => true do |t|
    t.string   "session_token"
    t.integer  "player_id"
    t.datetime "expired_at"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "tokens", ["player_id"], :name => "fk_tokens_player_id"

  create_table "transaction_slips", :force => true do |t|
    t.integer  "casino_id",    :null => false
    t.integer  "slip_type_id", :null => false
    t.integer  "next_number",  :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "transaction_slips", ["casino_id", "slip_type_id"], :name => "index_transaction_slips_on_property_id_and_slip_type_id", :unique => true
  add_index "transaction_slips", ["slip_type_id"], :name => "fk_transaction_slips_slip_type_id"

  create_table "transaction_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "purge_at"
  end

  create_table "transaction_types_slip_types", :force => true do |t|
    t.integer  "casino_id",           :null => false
    t.integer  "transaction_type_id", :null => false
    t.integer  "slip_type_id",        :null => false
    t.datetime "purge_at"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "transaction_types_slip_types", ["casino_id", "transaction_type_id"], :name => "index_trans_types_slip_types_on_property_id_and_trans_type_id", :unique => true
  add_index "transaction_types_slip_types", ["slip_type_id"], :name => "fk_transaction_types_slip_types_slip_type_id"
  add_index "transaction_types_slip_types", ["transaction_type_id"], :name => "fk_transaction_types_slip_types_transaction_type_id"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "uid"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "purge_at"
    t.integer  "casino_id",  :null => false
  end

  add_index "users", ["casino_id"], :name => "fk_users_casino_id"

end
