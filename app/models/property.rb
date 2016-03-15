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
      casino = Property.find(property_id).casino
      return nil unless casino
      casino.id
    end

    def get_licensee_id_by_property_id(property_id)
      casino = Property.find(property_id).casino
      return nil unless casino
      casino.licensee.id
    end
  end
end
