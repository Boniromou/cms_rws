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

  def get_permission_attribute(target, action)
    cache_key = "#{APP_NAME}:permissions:#{self.uid}"
    permissions = Rails.cache.fetch cache_key
    attributes = permissions[:permissions][:attributes]
    if attributes.has_key(target)
      attributes = attributes[target]
      if attributes.has_key(action)
        return attributes[action]
      end
    end
    nil
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
