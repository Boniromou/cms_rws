class Configuration < ActiveRecord::Base
	attr_accessible :casino_id, :key, :value, :description
end
