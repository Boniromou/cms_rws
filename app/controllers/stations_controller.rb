class StationsController < ApplicationController
  layout 'cage'
  skip_before_filter :check_session_expiration, :authenticate_user!, :only => :current

  STATION_STATUS = { 
    :active => { :action_str => "enable", :redirect_page => "inactive"},
    :inactive => { :action_str => "disable", :redirect_page => "active"}
    }

  def list
    return unless permission_granted? Station.new
    @status = params[:status]
    @stations = Station.where('status' => @status) || []
  end

  def create
    return unless permission_granted? Station.new
    name = params[:name].upcase
    location_id = params[:location_id]
    begin
      AuditLog.player_log("create", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        Station.create_by_params(params)
      end
      flash[:success] = {key: "station.add_success", replace: {:name => name, :location => Location.get_name_by_id(location_id)}}
    rescue StationError::ParamsError => e
      flash[:error] = "station." + e.message
    rescue StationError::DuplicatedFieldError => e
      flash[:error] = {key: "station.already_existed", replace: {:name => name, :location => Location.get_name_by_id(location_id)}}
    ensure
      redirect_to list_stations_path("active")
    end
  end

  def change_status
    return unless permission_granted? Station.new
    target_status = params[:target_status]
    station_id = params[:station_id]
    station = Station.find(station_id)
    action_str = STATION_STATUS[target_status.to_sym][:action_str]
    redirect_page = STATION_STATUS[target_status.to_sym][:redirect_page]
    begin
    	AuditLog.station_log(action_str, current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        station.change_status(target_status)
      end
      flash[:success] = {key: "station." + action_str + "_success", replace: {:name => station.name}}
    rescue StationError::EnableFailError => e
      flash[:error] = "station." + e.message
    rescue StationError::AlreadyEnabledError => e
      flash[:error] = {key: "station.already_" + action_str + "d", replace: {:name => station.name}}
    ensure
      redirect_to list_stations_path(redirect_page)
    end
  end

  def register
    return unless permission_granted? Station.new
    machine_id = params[:machine_id]
    station_id = params[:station_id]
    station = Station.find(station_id)
    begin
    	AuditLog.station_log("register", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        station.register(machine_id)
      end
      flash[:success] = {key: "machine_id.register_success", replace: {:station_name => station.full_name}}
    rescue StationError::StationAlreadyRegisterError => e
      flash[:error] = "machine_id.station_already_reg"
    rescue StationError::MachineAlreadyRegisterError => e
      flash[:error] = "machine_id.machine_already_reg"
    ensure
      if station.status == "active"
        redirect_to list_stations_path("active")
      else
        redirect_to list_stations_path("inactive")
      end
    end
  end

  def unregister
    return unless permission_granted? Station.new
    station_id = params[:station_id]
    station = Station.find(station_id)
    begin
    	AuditLog.station_log("unregister", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        station.unregister
      end
      flash[:success] = {key: "machine_id.register_success", replace: {:station_name => station.full_name}}
    rescue StationError::StationAlreadyUnregisterError => e
      flash[:error] = "machine_id.unregister_fail"
    ensure
      redirect_to list_stations_path(station.status)
    end
  end
  
  def current
    machine_id = params[:machine_id]
    @current_station = Station.get_full_name_by_machine_id(machine_id)
    respond_to do |format|
      format.html { render "stations/current", :layout => false }
    end
  end
end
