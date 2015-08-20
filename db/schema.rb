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

ActiveRecord::Schema.define(:version => 20150709014032) do

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
  end

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "status"
  end

  create_table "player_transactions", :force => true do |t|
    t.integer  "shift_id"
    t.integer  "player_id"
    t.integer  "user_id"
    t.integer  "transaction_type_id"
    t.string   "status"
    t.integer  "amount",              :limit => 8
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "station_id"
    t.string   "ref_trans_id"
  end

  add_index "player_transactions", ["player_id"], :name => "fk_player_id"
  add_index "player_transactions", ["shift_id"], :name => "fk_shift_id"
  add_index "player_transactions", ["transaction_type_id"], :name => "fk_transaction_type_id"
  add_index "player_transactions", ["user_id"], :name => "fk_playerTransaction_user_id"

  create_table "players", :force => true do |t|
    t.string   "member_id"
    t.string   "card_id"
    t.integer  "currency_id"
    t.string   "status"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "first_name"
    t.string   "last_name"
  end

  add_index "players", ["card_id"], :name => "index_players_on_card_id", :unique => true
  add_index "players", ["currency_id"], :name => "fk_currency_id"
  add_index "players", ["member_id"], :name => "by_member_id", :unique => true

  create_table "shift_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "shifts", :force => true do |t|
    t.integer  "shift_type_id"
    t.integer  "roll_shift_by_user_id"
    t.datetime "roll_shift_at"
    t.integer  "roll_shift_on_station_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.integer  "accounting_date_id"
    t.integer  "lock_version"
  end

  add_index "shifts", ["accounting_date_id"], :name => "fk_accounting_date_id"
  add_index "shifts", ["roll_shift_by_user_id"], :name => "fk_user_id"
  add_index "shifts", ["roll_shift_on_station_id"], :name => "fk_station_id"
  add_index "shifts", ["shift_type_id"], :name => "fk_shift_type_id"

  create_table "stations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "machine_id"
    t.integer  "location_id"
    t.string   "status"
  end

  add_index "stations", ["location_id"], :name => "fk_location_id"

  create_table "transaction_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "employee_id"
    t.string   "uid"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

end
