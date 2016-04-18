class Property < ActiveRecord::Base
  attr_accessible :name, :secret_key
  belongs_to :casino

  class << self
    def get_property_keys
      r = {}
      Property.all.each {|p| r[p.id] = p.secret_key}
      r
    end

    def get_casino_id_by_property_id(property_id)
      property = Property.find_by_id(property_id)
      if property && property.casino
        return property.casino.id
      else
        return nil
      end
    end

    def get_licensee_id_by_property_id(property_id)
      property = Property.find_by_id(property_id)
      if property && property.casino && property.casino.licensee
        return property.casino.licensee.id
      else
        return nil
      end
    end
  end
end
