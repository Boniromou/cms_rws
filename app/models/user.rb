class User < ActiveRecord::Base
  devise :registerable

  attr_accessible :employee_id, :uid

  def set_have_enable_station(have_enable_station)
  	@have_enable_station = have_enable_station
  end

  def have_enable_station
  	@have_enable_station
  end
end
