module Hood
  class Property < Sequel::Model
    class << self
      @@time_zones = {}

      def get_property_keys
        r = {}
        Property.all.each {|p| r[p.id] = p.secret_key}
        r
      end

      def get_time_zone(property_id)
        @@time_zones[property_id] || 
          @@time_zones[property_id]= (Property[property_id][:time_zone] || "+08:00")
      end
    end
  end
end

