class User < ActiveRecord::Base
  devise :registerable

  attr_accessible :name, :uid, :property_id

  def set_have_active_location(have_active_location)
  	@have_active_location = have_active_location
  end

  def have_active_location
  	@have_active_location
  end

  def is_admin?
    user = Rails.cache.fetch "#{self.uid}"
    user && user[:admin]
  end

  class << self
    def get_property_ids_by_uid(uid)
      user = Rails.cache.fetch "#{uid}"
      if user && user[:properties]
        user[:properties]
      else
        []
      end
    end
  end
end
