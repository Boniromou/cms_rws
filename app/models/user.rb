class User < ActiveRecord::Base
  devise :registerable
  belongs_to :casino

  attr_accessible :name, :uid, :casino_id

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

  def get_permission_value(target, action)
    cache_key = "#{APP_NAME}:permissions:#{self.uid}"
    permissions = Rails.cache.fetch cache_key
    permissions[:permissions][:values][target][action]
  rescue => e
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
    
    def get_casino_ids_by_uid(uid)
      user = Rails.cache.fetch "#{uid}"
      if user && user[:casinos]
        user[:casinos]
      else
        []
      end
    end
  end
end
