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
require File.expand_path("../../app/models/shift", __FILE__)
require File.expand_path("../../app/models/shift_type", __FILE__)
require File.expand_path("../../app/models/casinos_shift_type", __FILE__)
require File.expand_path("../../app/models/accounting_date", __FILE__)
require File.expand_path("../../app/models/player_transaction", __FILE__)
require File.expand_path("../../app/models/config_helper", __FILE__)
require File.expand_path("../../app/models/configuration", __FILE__)
#require File.expand_path("../../app/models/kiosk_transaction", __FILE__)
DB = connect_db(database)
config_table = DB[:configurations]
player_transactions_table = DB[:player_transactions]
casino_table = DB[:casinos]
shift_table = DB[:shifts]

casino_table.all.each do |record|
  casino_id = record[:id]
  player_transactions_table.where(:shift_id => nil, :casino_id => casino_id).each do |transaction|
    current_datetime = DateTime.now.utc
    current_shift = Shift.current(casino_id)
    shift_num = ConfigHelper.new(casino_id).send "roll_shift_time"
    current_shift_started_at = DateTime.parse(current_shift.started_at.strftime('%a, %e %b %Y %H:%M:%S'))
        #p current_datetime
        #p DateTime.now
        #p DateTime.parse(current_shift.started_at.strftime('%a, %e %b %Y %H:%M:%S'))
        #p  current_shift.started_at + (24 / shift_num.split(',').count).hours
      if current_datetime.between?(current_shift_started_at, current_shift_started_at + (24 / shift_num.split(',').count).hours)
        transaction_day = transaction[:updated_at].change(hour: 0) 
        shift_table.where(started_at: transaction_day..transaction_day + 1.days, :casino_id => casino_id).each do |shift|
          #p '3333333333333333333333333333333333333333
          p shift[:started_at]
          p transaction[:updated_at]
          #p '3333333333333333333333333333333333333333'          
          if transaction[:updated_at].between?(shift[:started_at], shift[:started_at] + (24 / shift_num.split(',').count).hours)
            p '4444444444444444444444444444444444444'
            @transaction = PlayerTransaction.find_by_id(transaction[:id])
            @transaction.shift_id = shift[:id]
            @transaction.save
          end
        end
      end
  end
end

