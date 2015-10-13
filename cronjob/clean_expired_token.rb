require 'active_record'

env = $*[0] || "development"
database = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'database.yml'))
DB = database[env]
ActiveRecord::Base.establish_connection(:adapter => "mysql",
                                        :host => DB['host'],
                                        :username => DB['username'],
                                        :password => DB['password'],
                                        :database => DB['database'],
                                        :port => DB['port'])

class Token < ActiveRecord::Base
  class << self
    def clean_expired_tokens
      tokens = Token.where('expired_at < ?', Time.now)
      puts "#{tokens.length} tokens expired"
      tokens.delete_all        
    end
  end
end

class CleanTokenHelper
  def run
    Token.clean_expired_tokens
  end
end

puts "*************** #{Time.now.utc} ****************"
puts "Start cleaning expired tokens"
CleanTokenHelper.new.run
puts "Finish cleaning expired tokens"
puts "*************** #{Time.now.utc} ****************"
