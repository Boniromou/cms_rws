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
    location_id = params[:location]
    station_name = params[:name]
    begin
      AuditLog.player_log("create", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        Station.create_by_params(params)
      end
      flash[:success] = {key: "station.add_success", replace: {name: station_name}}
      redirect_to list_stations_path("active")
    rescue CreatePlayer::ParamsError => e
      flash[:error] = "create_player." + e.message
      redirect_to :action => 'new', :card_id => params[:player][:card_id], :member_id => params[:player][:member_id], :first_name => params[:player][:first_name], :last_name => params[:player][:last_name]
    rescue CreatePlayer::DuplicatedFieldError => e
      field = e.message
      flash[:error] = {key: "create_player." + field + "_exist", replace: {field.to_sym => params[:player][field.to_sym]}}
      redirect_to :action => 'new', :card_id => params[:player][:card_id], :member_id => params[:player][:member_id], :first_name => params[:player][:first_name], :last_name => params[:player][:last_name]
    end

  end
end
