require 'active_record'
require File.expand_path("../../app/models/approval_request",__FILE__)
require File.expand_path("../../app/models/approval_log",__FILE__)
#require File.expand_path("../../app/models/player_transaction",__FILE__)
#require File.expand_path("../../app/models/player",__FILE__)
require File.expand_path("../../lib/approval_helper",__FILE__)

env = $*[0] || "development"
database = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'database.yml'))
DB = database[env]
ActiveRecord::Base.establish_connection(:adapter => "mysql2",
                                        :host => DB['host'],
                                        :username => DB['username'],
                                        :password => DB['password'],
                                        :database => DB['database'],
                                        :port => DB['port'])

class PlayerTransaction < ActiveRecord::Base
end
class Player < ActiveRecord::Base
end

puts "*************** #{Time.now.utc} ****************"
puts "Start running approved transaction"
Cronjob::ApprovalHelper.new(env).run

#p PlayerTransaction.first                                                                                 
puts "Finish running approved transaction"
puts "*************** #{Time.now.utc} ****************"

