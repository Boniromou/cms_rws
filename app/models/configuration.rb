class Configuration < ActiveRecord::Base
	attr_accessible :property_id, :key, :value, :description
    class << self
      def write_config(config, property_id)
      	config.each do |key, value|
          Configuration.create!(:property_id => property_id, :key => key, :value => value[0], :description => value[1]) 
        end
      end

      def retrieve_config(key)
        Configuration.find_by_key_and_property_id(key, PROPERTY_ID).value.to_i
      end
    end
end