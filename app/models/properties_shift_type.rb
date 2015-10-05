class PropertiesShiftType < ActiveRecord::Base
  attr_accessible :property_id, :shift_type_id, :sequence
  belongs_to :property
  belongs_to :shift_type

  class << self
    def shift_types(property_id)
      shift_names = []
      properties_shift_types = PropertiesShiftType.order(:sequence => :asc).where(:property_id => property_id)
      properties_shift_types.each do |properties_shift_type|
        shift_names << properties_shift_type.shift_type.name
      end
      shift_names
    end
  end
end
