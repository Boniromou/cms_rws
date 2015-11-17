require 'active_record'
require 'action_view'
require File.expand_path("../../app/helpers/fund_helper", __FILE__)
require File.expand_path("../../app/models/player", __FILE__)
require File.expand_path("../../app/models/players_lock_type", __FILE__)
require File.expand_path("../../app/models/lock_type", __FILE__)
require File.expand_path("../../app/models/token", __FILE__)
require File.expand_path("../../app/models/property", __FILE__)
require File.expand_path("../../lib/requester/patron", __FILE__)
require File.expand_path("../../lib/errors", __FILE__)
require File.expand_path("../lib/update_player_helper",__FILE__)

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
puts "Start update players"
Cronjob::UpdatePlayerHelper.new(env).run
puts "Finish update plsyers"
puts "*************** #{Time.now.utc} ****************"
