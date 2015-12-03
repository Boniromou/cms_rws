class Machine < ActiveRecord::Base
  class << self
		def validate(machine_type, machine_token, property_id)
      @station_requester = REQUESTER_FACTORY.get_station_requester
    	response = @station_requester.validate_machine_token(machine_type, machine_token, property_id)  
   	end

    def parse_machine_token(machine_token)
      Davis::Util.get_machine_config(machine_token)
    end
	end
end
