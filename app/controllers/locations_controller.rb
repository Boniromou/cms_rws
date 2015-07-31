class LocationsController < ApplicationController
layout 'cage'
  include FormattedTimeHelper

  def list
    return unless permission_granted? Location.new
    
    @status = params[:status]
    @locations = Location.where('status' => @status) || []
  end

  def add
    return unless permission_granted? Location.new
    begin
      AuditLog.location_log("add", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
      Location.create_by_name(params[:name])
    end

    flash[:success] = {key: "location.add_success", replace: {name: params[:name].upcase}}
    redirect_to list_locations_path('active')
    rescue LocationError::AlreadyExistedError => e
      flash[:error] = { key: "location.already_existed", replace: {name: params[:name].upcase}}
      redirect_to list_locations_path('active')
    rescue LocationError::CantBlankError => e
      flash[:error] = "location." + e.message
      redirect_to list_locations_path('active')
    end
  end
  
  def change_status
    return unless permission_granted? Location.new
    target_status = params[:target_status]
    location_id = params[:location_id]
    location = Location.find(location_id)
    action_str = CHANGE_STATUS_HELPER[target_status.to_sym][:action_str]
    redirect_page = CHANGE_STATUS_HELPER[target_status.to_sym][:redirect_page]
    begin
      AuditLog.location_log(action_str, current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        location.change_status(target_status)
      end
      flash[:success] = {key: "location." + action_str + "_success", replace: {:name => location.name.upcase}}
    rescue LocationError::DisableFailError => e
      flash[:error] = "location." + e.message
    rescue LocationError::DuplicatedChangeStatusError => e
      flash[:error] = {key: "location.already_" + action_str + "d", replace: {:name => location.name.upcase}}
    ensure
      redirect_to list_locations_path(redirect_page)
    end
  end

end