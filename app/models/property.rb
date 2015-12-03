class Property < ActiveRecord::Base
  attr_accessible :name, :secret_key

  class << self
    def get_property_keys
      r = {}
      Property.all.each {|p| r[p.id] = p.secret_key}
      r
    end

    def current_property_id
      20000
    end
  end
end
