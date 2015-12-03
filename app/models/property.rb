class Property < ActiveRecord::Base
  attr_accessible :name, :secret_key

  class << self
    def get_property_keys
      r = {}
      Property.all.each {|p| r[p.id] = p.secret_key}
      r
    end
  end
end
