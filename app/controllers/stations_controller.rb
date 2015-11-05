class StationsController < ApplicationController
  layout 'cage'
  skip_before_filter :check_session_expiration, :authenticate_user!,:pass_terminal_id, :only => :current
  include StationHelper

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
      AuditLog.station_log("create", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        Station.create_by_params(params)
      end
      flash[:success] = {key: "station.add_success", replace: {:name => name, :location => Location.get_name_by_id(location_id)}}
    rescue StationError::ParamsError => e
      flash[:error] = "station." + e.message
    rescue StationError::InvalidLocationError
      flash[:error] = "station.location_invalid"
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
    action_str = STATUS_HELPER[target_status.to_sym][:action_str]
    redirect_page = STATUS_HELPER[target_status.to_sym][:opposite]
    begin
    	AuditLog.station_log(action_str, current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        station.change_status(target_status)
      end
      flash[:success] = {key: "station." + action_str + "_success", replace: {:name => station.full_name}}
    rescue StationError::EnableFailError => e
      flash[:error] = "station." + e.message
    rescue StationError::AlreadyEnabledError => e
      flash[:error] = {key: "station.already_" + action_str + "d", replace: {:name => station.full_name}}
    ensure
      redirect_to list_stations_path(redirect_page)
    end
  end

  def register
    return unless permission_granted? Station.new
    terminal_id = params[:terminal_id]
    station_id = params[:station_id]
    station = Station.find(station_id)
    begin
    	AuditLog.station_log("register", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        station.register(terminal_id)
      end
      flash[:success] = {key: "terminal_id.register_success", replace: {:station_name => station.full_name}}
    rescue StationError::StationAlreadyRegisterError => e
      flash[:error] = "terminal_id.station_already_reg"
    rescue StationError::TerminalAlreadyRegisterError => e
      flash[:error] = {key: "terminal_id.terminal_already_reg", replace: {:station_name => Station.get_full_name_by_terminal_id(terminal_id)}}
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
    	AuditLog.station_log("unregister", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        station.unregister
      end
      flash[:success] = {key: "terminal_id.unregister_success", replace: {:station_name => station.full_name}}
    rescue StationError::StationAlreadyUnregisterError => e
      flash[:error] = "terminal_id.unregister_fail"
    ensure
      redirect_to list_stations_path(station.status)
    end
  end
  
  def current
    # terminal_id = params[:terminal_id]
    # @current_station = Station.get_full_name_by_terminal_id(terminal_id)
    @current_station = get_location_name
    respond_to do |format|
      format.html { render "stations/current", :layout => false }
    end
  end
end