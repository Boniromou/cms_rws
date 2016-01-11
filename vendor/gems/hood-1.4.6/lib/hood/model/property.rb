module Hood
  class Property < Sequel::Model
    class << self
      @@time_zones = {}
      @@credit_enables = {}

      #for test case
      def reset
        @@time_zones = {}
        @@credit_enables = {}
      end

      def get_property_keys
        r = {}
        Property.all.each {|p| r[p.id] = p.secret_key}
        r
      end

      def get_time_zone(property_id)
        @@time_zones[property_id] || 
          @@time_zones[property_id]= (Property[property_id][:time_zone] || "+08:00")
      end

      def credit_enable?(property_id)
        @@credit_enables[property_id] ||
          @@credit_enables[property_id] = (Property[property_id][:credit_mode]) != nil
      end

    end
  end
end

