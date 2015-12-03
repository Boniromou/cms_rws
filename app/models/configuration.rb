class Configuration < ActiveRecord::Base
	attr_accessible :property_id, :key, :value, :description
end
