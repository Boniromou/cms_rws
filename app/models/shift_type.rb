class ShiftType < ActiveRecord::Base
  attr_accessible :name

  class << self
    def get_id_by_name( shift_name )
      ShiftType.find_by_name(shift_name).id
    end

    def get_name_by_id( id )
      ShiftType.find_by_id(id).name
    end
  end
end
