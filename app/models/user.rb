class User < ActiveRecord::Base
  devise :registerable

  attr_accessible :name, :uid

  def set_have_enable_station(have_enable_station)
  	@have_enable_station = have_enable_station
  end

  def have_enable_station
  	@have_enable_station
  end
end
