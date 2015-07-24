class StationsController < ApplicationController
  layout 'cage'

  def list
    return unless permission_granted? Station.new
    @status = params[:status]
    @stations = Station.where('status' => @status) || []
  end

  def create
    return unless permission_granted? Station.new
    name = params[:name]
    location_id = params[:location_id]
    begin
      AuditLog.player_log("create", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        Station.create_by_params(params)
      end
      flash[:success] = {key: "station.add_success", replace: {:name => name, :location => Location.get_name_by_id(location_id)}}
      redirect_to list_stations_path("active")
    rescue StationError::ParamsError => e
      flash[:error] = e.message
      redirect_to list_stations_path("active")
    rescue StationError::DuplicatedFieldError => e
      flash[:error] = {key: "station.already_existed", replace: {:name => name, :location => Location.get_name_by_id(location_id)}}
      redirect_to list_stations_path("active")
    end
  end

  def change_status
    return unless permission_granted? Station.new
    puts "params",params
    p "change_status"
    begin
      target_status = params[:change_to_status]
    	station_id = params[:station_id]
    	station = Station.find(station_id)
      action_str = ""
      action_str = "disable" if target_status == "inactive"
      action_str = "enable" if target_status == "active"
    	AuditLog.station_log(action_str, current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        station.change_status(target_status)
      end
      flash[:success] = { key: "station.disable_success", replace: {name: station.name.upcase}}
      redirect_to list_stations_path('active')
    rescue StationError::EnableStationError => e
      flash[:error] = "station." + e.message
      redirect_to list_stations_path('active')
    rescue StationError::AlreadyEnabledError => e
      flash[:error] = { key: "station.already_disabled", replace: {name: station.name.upcase}}
      redirect_to list_stations_path('active')
    end
  end

  
  def disable
    return unless permission_granted? Station.new
    begin
    	station_id = params[:station_id]
    	station = Station.find(station_id)
    	AuditLog.station_log("disable", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        station.disable!
      end
      flash[:success] = { key: "station.disable_success", replace: {name: station.name.upcase}}
      redirect_to list_stations_path('active')
    rescue DisableStation::DisableFailError => e
      flash[:error] = "station." + e.message
      redirect_to list_stations_path('active')
    rescue DisableStation::AlreadyDisabledError => e
      flash[:error] = { key: "station.already_disabled", replace: {name: station.name.upcase}}
      redirect_to list_stations_path('active')
    end
  end
end
