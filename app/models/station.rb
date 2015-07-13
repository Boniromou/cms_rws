class Station < ActiveRecord::Base
  attr_accessible :name
  class << self
    def get_name_by_id( id )
      Station.find_by_id(id).name
    end

    def active_stations
      Station.find_by_status("active")
    end
    
    def inactive_stations
      Station.find_by_status("inactive")
    end
  end
end
