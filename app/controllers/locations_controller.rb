class LocationsController < ApplicationController
layout 'cage'
  include FormattedTimeHelper

  def list
    return unless permission_granted? Location.new
    
    @status = params[:status]
    @locations = Location.where('status' => @status) || []
  end

  def create
    return unless permission_granted? Location.new
    begin
      AuditLog.location_log("add", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
      Location.create_by_name(params[:location_name])
    end

    flash[:success] = {key: "location.add_success", replace: {name: params[:location_name].upcase}}
    redirect_to list_locations_path('active')
    rescue AddLocation::AlreadyExistedError => e
      flash[:error] = { key: "location.already_existed", replace: {name: params[:location_name].upcase}}
      redirect_to list_locations_path('active')
    rescue AddLocation::CantBlankError => e
      flash[:error] = "location." + e.message
      redirect_to list_locations_path('active')
    end
  end
  

  def disable
    return unless permission_granted? Location.new
    begin
    	location_id = params[:location_id]
    	location = Location.find(location_id)
    	AuditLog.location_log("disable", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        location.disable!
      end

      flash[:success] = { key: "location.disable_success", replace: {name: location.name.upcase}}
      redirect_to list_locations_path('active')
    rescue DisableLocation::DisableFailError => e
      flash[:error] = "location." + e.message
      redirect_to list_locations_path('active')
    rescue DisableLocation::AlreadyDisabledError => e
      flash[:error] = { key: "location.already_disabled", replace: {name: location.name.upcase}}
      redirect_to list_locations_path('active')
    end
  end

  def enable
    return unless permission_granted? Location.new
  	begin
      location_id = params[:location_id]
      location = Location.find(location_id)
      AuditLog.location_log("enable", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        location.enable!
      end
      flash[:success] = { key: "location.enable_success", replace: {name: location.name.upcase}}
      redirect_to list_locations_path('inactive')
    rescue DisableLocation::AlreadyEnabledError => e
      flash[:error] = { key: "location.already_enabled", replace: {name: location.name.upcase}}
      redirect_to list_locations_path('inactive')
    end
  end
end