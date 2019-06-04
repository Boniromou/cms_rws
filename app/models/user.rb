class User < ActiveRecord::Base
  devise :registerable

  attr_accessible :name, :uid

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

  def username_with_domain
    user = Rails.cache.fetch "#{self.uid}"
    user[:username_with_domain] if user
  end

  def get_permission_value(target, action)
    cache_key = "#{APP_NAME}:permissions:#{self.uid}"
    permissions = Rails.cache.fetch cache_key
    permissions[:permissions][:values][target][action]
  rescue => e
    nil
  end

  def casino
    Casino.find_by_id(casino_id)
  end

  def casino_id
    casino_ids.first
  end

  def casino_ids
    User.get_casino_ids_by_uid(self.uid)
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

class MockUser < User
  attr_reader :name, :casino_id
  def initialize(hash)
    @name = hash[:name]
    @casino_id = hash[:casino_id]
  end
end
