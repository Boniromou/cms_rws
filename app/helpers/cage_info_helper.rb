module CageInfoHelper
  def current_cage_location_str
    current_station.capitalize + "!!!"
  end

  protected

  def current_station
    "window#1"
  end
end
