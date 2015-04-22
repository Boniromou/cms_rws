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

ActiveRecord::Schema.define(:version => 20150422095027) do

  create_table "accounting_dates", :force => true do |t|
    t.date     "accounting_date"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

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
  end

  create_table "currencies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "purge_at"
  end

  create_table "player_infos", :force => true do |t|
    t.string   "player_name"
    t.string   "member_id"
    t.string   "card_id"
    t.integer  "player_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "player_infos", ["card_id"], :name => "by_card_id", :unique => true
  add_index "player_infos", ["member_id"], :name => "by_member_id", :unique => true
  add_index "player_infos", ["player_id"], :name => "fk_info_player_id"

  create_table "players", :force => true do |t|
    t.string   "login_name"
    t.integer  "currency_id",              :null => false
    t.integer  "balance",     :limit => 8
    t.string   "lock_state"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "shareholder"
    t.datetime "played_at"
    t.datetime "purge_at"
    t.integer  "property_id",              :null => false
  end

  add_index "players", ["currency_id"], :name => "fk_currency_id"
  add_index "players", ["property_id"], :name => "fk_property_id"

  create_table "properties", :force => true do |t|
    t.string   "name"
    t.string   "secret_key"
    t.string   "time_zone"
    t.datetime "purge_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "round_transactions", :force => true do |t|
    t.string   "ref_trans_id",                                                  :null => false
    t.integer  "bet_amt",          :limit => 8
    t.integer  "payout_amt",       :limit => 8
    t.integer  "win_amt",          :limit => 8
    t.integer  "before_balance",   :limit => 8
    t.integer  "after_balance",    :limit => 8
    t.string   "aasm_state"
    t.string   "trans_type",                                                    :null => false
    t.datetime "trans_date"
    t.integer  "round_id",         :limit => 8
    t.integer  "internal_game_id"
    t.integer  "external_game_id"
    t.decimal  "pc_jp_con_amt",                 :precision => 25, :scale => 10
    t.decimal  "pc_jp_win_amt",                 :precision => 25, :scale => 10
    t.decimal  "jc_jp_con_amt",                 :precision => 25, :scale => 10
    t.decimal  "jc_jp_win_amt",                 :precision => 25, :scale => 10
    t.string   "jp_win_id"
    t.integer  "jp_win_lev"
    t.integer  "jp_direct_pay",    :limit => 1
    t.integer  "property_id",                                                   :null => false
    t.integer  "player_id",                                                     :null => false
    t.datetime "purge_at"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
  end

  add_index "round_transactions", ["player_id"], :name => "fk_round_trans_player_id"

  create_table "shift_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "shifts", :force => true do |t|
    t.integer  "shift_type_id"
    t.integer  "user_id"
    t.datetime "roll_shift_at"
    t.string   "station"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "accounting_date_id"
  end

  add_index "shifts", ["accounting_date_id"], :name => "fk_accounting_date_id"
  add_index "shifts", ["shift_type_id"], :name => "fk_shift_type_id"
  add_index "shifts", ["user_id"], :name => "fk_user_id"

  create_table "users", :force => true do |t|
    t.string   "employee_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "uid"
  end

  create_table "wallet_transaction_infos", :force => true do |t|
    t.integer  "shift_id"
    t.integer  "user_id"
    t.string   "station"
    t.integer  "wallet_transaction_id", :limit => 8
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "wallet_transaction_infos", ["shift_id"], :name => "fk_shift_id"
  add_index "wallet_transaction_infos", ["user_id"], :name => "fk_transaction_info_user_id"
  add_index "wallet_transaction_infos", ["wallet_transaction_id"], :name => "fk_info_wallet_id"

  create_table "wallet_transactions", :force => true do |t|
    t.string   "ref_trans_id",                :null => false
    t.integer  "amt",            :limit => 8
    t.integer  "before_balance", :limit => 8
    t.integer  "after_balance",  :limit => 8
    t.string   "aasm_state"
    t.string   "trans_type",                  :null => false
    t.datetime "trans_date"
    t.integer  "property_id",                 :null => false
    t.integer  "player_id",                   :null => false
    t.datetime "purge_at"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "wallet_transactions", ["player_id"], :name => "fk_player_id"

end
