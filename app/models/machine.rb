class Machine < ActiveRecord::Base
    class << self
		def validate(machine_type, machine_token, property_id)
			@station_requester = Requester::Station.new(STATION_URL)
    		response = @station_requester.validate_machine_token(machine_type, machine_token, property_id)  
   	 	end
	end
end
