class StationsController < ApplicationController
  layout 'cage'

  def list
    return unless permission_granted? Station.new
    puts "params",params
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
    rescue CreateStation::ParamsError => e
      flash[:error] = e.message
      redirect_to list_stations_path("active")
    rescue CreateStation::DuplicatedFieldError => e
      flash[:error] = {key: "station.already_existed", replace: {:name => name, :location => Location.get_name_by_id(location_id)}}
      redirect_to list_stations_path("active")
    end

  end
end
