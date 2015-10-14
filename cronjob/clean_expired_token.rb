require 'active_record'
require File.expand_path("../lib/token",__FILE__)
require File.expand_path("../lib/clean_token_helper",__FILE__)

env = $*[0] || "development"
database = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'database.yml'))
DB = database[env]
ActiveRecord::Base.establish_connection(:adapter => "mysql2",
                                        :host => DB['host'],
                                        :username => DB['username'],
                                        :password => DB['password'],
                                        :database => DB['database'],
                                        :port => DB['port'])

puts "*************** #{Time.now.utc} ****************"
puts "Start cleaning expired tokens"
Cronjob::CleanTokenHelper.new.run
puts "Finish cleaning expired tokens"
puts "*************** #{Time.now.utc} ****************"
