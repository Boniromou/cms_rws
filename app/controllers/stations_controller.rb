class StationsController < ApplicationController
  layout 'cage'

  def list
    return unless permission_granted? Station.new
    @active_stations = Station.active_stations
    @inactive_stations = Station.inactive_stations
  end

  def create
    return unless permission_granted? Station.new
  end
end
