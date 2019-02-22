require 'active_record'
require 'action_view'
require 'sequel'
require 'yaml'
require 'logger'

RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + "/../..") unless defined?(RAILS_ROOT)

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

env = $*[0] 
casino_id = $*[1]
roll_times = ($*[2] || 1).to_i
if env.nil? || casino_id.nil?
  puts "Usage: ruby xxx.rb [env] [casino_id] [roll_times = 1]"
  exit
end
database = YAML.load_file("#{RAILS_ROOT}/config/database.yml")[env]
ActiveRecord::Base.establish_connection(:adapter => "mysql2",
                                        :host => database['host'],
                                        :username => database['username'],
                                        :password => database['password'],
                                        :database => database['database'],
                                        :port => database['port'])

require File.expand_path("#{RAILS_ROOT}/app/helpers/fund_helper", __FILE__)
require File.expand_path("#{RAILS_ROOT}/app/helpers/front_money_helper", __FILE__)
require File.expand_path("#{RAILS_ROOT}/app/models/shift", __FILE__)
require File.expand_path("#{RAILS_ROOT}/app/models/shift_type", __FILE__)
require File.expand_path("#{RAILS_ROOT}/app/models/casinos_shift_type", __FILE__)
require File.expand_path("#{RAILS_ROOT}/app/models/accounting_date", __FILE__)
require File.expand_path("#{RAILS_ROOT}/app/models/config_helper", __FILE__)
require File.expand_path("#{RAILS_ROOT}/app/models/configuration", __FILE__)
puts '-------------------------------------------------'
puts "***************[start: #{Time.now.utc} ]****************"
roll_times.times do
  current_shift = Shift.current(casino_id)
  puts "current shift: #{current_shift.accounting_date}, #{current_shift.name}"
  current_shift.manual_roll!(nil, nil)
  current_shift = Shift.current(casino_id)
  puts "roll shift success, current shift: #{current_shift.accounting_date}, #{current_shift.name}"
  puts ''
end

puts "***************[end: #{Time.now.utc} ]****************"
puts '-------------------------------------------------'
