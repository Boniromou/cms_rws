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
require File.expand_path("../../app/models/shift", __FILE__)
require File.expand_path("../../app/models/shift_type", __FILE__)
require File.expand_path("../../app/models/properties_shift_type", __FILE__)
require File.expand_path("../../app/models/accounting_date", __FILE__)
DB = connect_db(database)
config_table = DB[:configurations]
property_table= DB[:properties]

property_table.all.each do |record|
	property_id = record[:id]
	if config_table.where(:property_id => property_id, :key => "roll_shift_time").first
		roll_shift_time = config_table.where(:property_id => property_id, :key => "roll_shift_time").first[:value].split(',')
		current_hour = Time.now.utc.hour.to_s
		if roll_shift_time.include?(current_hour)
			current_shift = Shift.current(property_id)
			puts '-------------------------------------------------'
			puts "*************** #{Time.now.utc} ****************"
      		puts "Start rolling shift for property_id #{property_id}, current shift & accounting date: #{current_shift.shift_type.name}, #{current_shift.accounting_date}"
			current_shift.roll!(nil, nil)
			puts "Rolling shift successfully! Current shift & accounting date: 		    #{Shift.current(property_id).shift_type.name}, #{Shift.current(property_id).accounting_date}"
     		puts "*************** #{Time.now.utc} ****************"
     		puts '-------------------------------------------------'
     		puts ''
     		puts ''
		end
	end
end