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

env = ARGV[0]
casino = ARGV[1]
delete_old_config = ARGV[2]
if env.nil? || casino.nil?
  puts "Usage: ruby xxx.rb [env] [casino_id]"
  exit
end

database = YAML.load_file("#{RAILS_ROOT}/config/database.yml")[env]
DB = connect_db(database)
ds = DB[:configurations]

configs = YAML.load_file("#{RAILS_ROOT}/script/init_scripts/configuration.yml")[env][casino.to_i]
puts "*************** #{Time.now.utc} ****************"
puts "Start writing config of casino: #{casino}"
if delete_old_config == 'true'
	ds.where(:casino_id => casino).delete
end
configs.each do |config|
	if ds.where(:key => config[0], :casino_id => casino).first
		ds.where(:key => config[0], :casino_id => casino).update(:value => config[1][0], 
																	 :description => config[1][1], 
																	 :updated_at => Time.now.utc)
	else
		ds.insert(:key => config[0], 
				  :casino_id => casino,
				  :value => config[1][0], 
				  :description => config[1][1], 
				  :created_at => Time.now.utc,
				  :updated_at => Time.now.utc)
	end
end

puts "Finish writing config"
puts "*************** #{Time.now.utc} ****************"
