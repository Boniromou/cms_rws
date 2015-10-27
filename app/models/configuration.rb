class Configuration < ActiveRecord::Base
	attr_accessible :property_id, :key, :value, :description
    class << self
      def write_config
      	property = $*[0] || 20000
      	config = YAML.load_file(File.join(Rails.root, 'config', 'configuration.yml'))
      	config.each do |k,v| 
          v.each {|key, value| Configuration.create!(:property_id => k, :key => key, :value => value[0], :description => value[1]) }
        end
      end

      def retrieve_config(key)
        Configuration.find_by_key_and_property_id(key, PROPERTY_ID).value.to_i
      end
    end
end