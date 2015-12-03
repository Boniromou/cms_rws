class User < ActiveRecord::Base
  devise :registerable

  attr_accessible :name, :uid, :property_id

  def set_have_active_location(have_active_location)
  	@have_active_location = have_active_location
  end

  def have_active_location
  	@have_active_location
  end
end
