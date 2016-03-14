class CasinosShiftType < ActiveRecord::Base
  attr_accessible :casino_id, :shift_type_id, :sequence
  belongs_to :casino
  belongs_to :shift_type

  class << self
    def shift_types(casino_id)
      shift_names = []
      casinos_shift_types = CasinosShiftType.order(:sequence => :asc).where(:casino_id => casino_id)
      casinos_shift_types.each do |casinos_shift_type|
        shift_names << casinos_shift_type.shift_type.name
      end
      shift_names
    end
  end
end
