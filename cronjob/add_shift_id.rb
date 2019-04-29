require 'active_record'
require 'action_view'
require 'sequel'
require 'yaml'
require 'logger'

RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + "/..") unless defined?(RAILS_ROOT)

def connect_db(db_config)
  Sequel.connect(sprintf('%s://%s:%s@%s:%s/%s',
    db_config['adapter'],
    db_config['username'],
    db_config['password'],
    db_config['host'],
    db_config['port'] || 3306,
    db_config['database']),
    :loggers=>[Logger.new($stdout)])
end

env = $*[0] || "development"
database = YAML.load_file("#{RAILS_ROOT}/config/database.yml")[env]
ActiveRecord::Base.establish_connection(:adapter => "mysql2",
                                        :host => database['host'],
                                        :username => database['username'],
                                        :password => database['password'],
                                        :database => database['database'],
                                        :port => database['port'])

require File.expand_path("../../app/helpers/fund_helper", __FILE__)
require File.expand_path("../../app/helpers/front_money_helper", __FILE__)
require File.expand_path("../../app/helpers/transaction_queries", __FILE__)
require File.expand_path("../../app/helpers/transaction_adapter", __FILE__)
require File.expand_path("../../app/models/shift", __FILE__)
require File.expand_path("../../app/models/shift_type", __FILE__)
require File.expand_path("../../app/models/casinos_shift_type", __FILE__)
require File.expand_path("../../app/models/accounting_date", __FILE__)
require File.expand_path("../../app/models/player_transaction", __FILE__)
require File.expand_path("../../app/models/kiosk_transaction", __FILE__)
require File.expand_path("../../app/models/config_helper", __FILE__)
require File.expand_path("../../app/models/configuration", __FILE__)
#require File.expand_path("../../app/models/kiosk_transaction", __FILE__)
DB = connect_db(database)
config_table = DB[:configurations]
player_transactions_table = DB[:player_transactions]
casino_table = DB[:casinos]
shift_table = DB[:shifts]
kiosk_transactions_table = DB[:kiosk_transactions]

casino_table.all.each do |record|
  casino_id = record[:id]
  player_transactions_table.where(:shift_id => nil, :casino_id => casino_id, :status => 'completed').each do |transaction|
    current_datetime = DateTime.now.utc

    #current_shift = Shift.current(casino_id)

    current_shift = shift_table.where(:roll_shift_at => nil, :casino_id  => casino_id).first
    shift_num = ConfigHelper.new(casino_id).send "roll_shift_time"

    current_shift_started_at = DateTime.parse(current_shift[:created_at].change(min: 0).strftime('%a, %e %b %Y %H:%M:%S'))

    if current_datetime >= current_shift_started_at and current_datetime < current_shift_started_at + (24 / shift_num.split(',').count).hours
#      transaction_day = transaction[:trans_date].change(hour: 0) 
 #     shift_table.where(created_at: transaction_day - 1.days..transaction_day + 1.days, :casino_id => casino_id).each do |shift|
       shift = shift_table.where("created_at <= ? and DATE_ADD(created_at, INTERVAL #{(24 / shift_num.split(',').count)} HOUR) > ? and casino_id = ?", transaction[:trans_date], transaction[:trans_date], casino_id).first
       player_transactions_table.where(:id => transaction[:id]).update(:shift_id => shift[:id], :updated_at => Time.now.utc.to_formatted_s(:db))
        #if transaction[:trans_date] >= shift[:created_at].change(min: 0) and transaction[:trans_date] < shift[:created_at].change(min: 0) + (24 / shift_num.split(',').count).hours
         # @transaction = PlayerTransaction.find_by_id(transaction[:id])
         # @transaction.shift_id = shift[:id]
         # @transaction.updated_at = Time.now.utc.to_formatted_s(:db)
         # @transaction.save
        #end
  #    end
    end
  end

  kiosk_transactions_table.where(:shift_id => nil, :casino_id => casino_id).each do |kiosk_transaction|
    current_datetime = DateTime.now.utc
    #current_shift = Shift.current(casino_id)
    current_shift = shift_table.where(:roll_shift_at => nil, :casino_id  => casino_id).first
    shift_num = ConfigHelper.new(casino_id).send "roll_shift_time"
      
    current_shift_started_at = DateTime.parse(current_shift[:created_at].change(min: 0).strftime('%a, %e %b %Y %H:%M:%S'))

    if current_datetime >= current_shift_started_at and current_datetime < current_shift_started_at + (24 / shift_num.split(',').count).hours
#      kiosk_transaction_day = kiosk_transaction[:trans_date].change(hour: 0) 
#      shift_table.where(created_at: kiosk_transaction_day - 1.days..kiosk_transaction_day + 1.days , :casino_id => casino_id).each do |shift|
#        if kiosk_transaction[:trans_date] >= shift[:created_at].change(min: 0) and kiosk_transaction[:trans_date] < shift[:created_at].change(min: 0) + (24 / shift_num.split(',').count).hours and kiosk_transaction[:status] == 'completed'
#          @ktransaction = KioskTransaction.find_by_id(kiosk_transaction[:id])
#          @ktransaction.shift_id = shift[:id]
#          @ktransaction.updated_at = Time.now.utc.to_formatted_s(:db)
#          @ktransaction.save

#        end
    shift = shift_table.where("created_at <= ? and DATE_ADD(created_at, INTERVAL #{(24 / shift_num.split(',').count)} HOUR) > ? and casino_id = ?", kiosk_transaction[:trans_date], kiosk_transaction[:trans_date], casino_id).first  
    kiosk_transactions_table.where(:id => kiosk_transaction[:id]).update(:shift_id => shift[:id], :updated_at => Time.now.utc.to_formatted_s(:db))
    end
  end
end


