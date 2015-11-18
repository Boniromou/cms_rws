require 'active_record'

env = $*[0] || "development"
database = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'database.yml'))
DB = database[env]
ActiveRecord::Base.establish_connection(:adapter => "mysql2",
                                        :host => DB['host'],
                                        :username => DB['username'],
                                        :password => DB['password'],
                                        :database => DB['database'],
                                        :port => DB['port'])

config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'configuration.yml'))
con = config[20000]

require File.expand_path("../../app/models/configuration", __FILE__)

puts "*************** #{Time.now.utc} ****************"
puts "Start writing config"
Configuration.write_config(con, 20000)
puts "Finish writing config"
puts "*************** #{Time.now.utc} ****************"
