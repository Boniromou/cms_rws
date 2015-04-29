class Station < ActiveRecord::Base
  attr_accessible :name
  class << self
    def get_name_by_id( id )
      Station.find_by_id(id).name
    end
  end
end
