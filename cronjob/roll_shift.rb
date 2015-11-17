require 'active_record'
require 'action_view'

env = $*[0] || "development"
database = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'database.yml'))
DB = database[env]
ActiveRecord::Base.establish_connection(:adapter => "mysql2",
                                        :host => DB['host'],
                                        :username => DB['username'],
                                        :password => DB['password'],
                                        :database => DB['database'],
                                        :port => DB['port'])


require File.expand_path("../../app/models/configuration", __FILE__)
require File.expand_path("../../config/initializers/application", __FILE__)
require File.expand_path("../../app/helpers/fund_helper", __FILE__)
require File.expand_path("../../app/helpers/front_money_helper", __FILE__)
require File.expand_path("../../app/models/shift", __FILE__)
require File.expand_path("../../app/models/shift_type", __FILE__)
require File.expand_path("../../app/models/properties_shift_type", __FILE__)
require File.expand_path("../../app/models/accounting_date", __FILE__)

puts "*************** #{Time.now.utc} ****************"
puts "Start rolling shift"
current_shift = Shift.current
current_shift.roll_by_system
puts "Finish rolling shift"
puts "*************** #{Time.now.utc} ****************"

