class Machine < ActiveRecord::Base
  class << self
    def parse_machine_token(machine_token)
      Davis::Util.get_machine_config(machine_token)
    end
	end
end
