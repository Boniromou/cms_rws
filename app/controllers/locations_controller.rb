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
      AuditLog.location_log("create", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        Location.create_by_name(params[:location_name])
      end

      flash[:success] = {key: "create_location.success", replace: {name: params[:location_name].upcase}}
      redirect_to :action => list_locations_path('active')
      rescue CreateLocation::ParamsError => e
        flash[:error] = "create_location." + e.message
        redirect_to :action => list_locations_path('active')
      rescue CreateLocation::DuplicatedFieldError => e
        field = e.message
        flash[:error] = {key: "create_location." + field + "_exist", replace: {field.to_sym => params[field.to_sym]}}
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

      flash[:success] = { key: "disable_location.success", replace: {name: location.name.upcase}}
      redirect_to list_locations_path('active')
    rescue Exception => e
      p e.message
      p e.class
      raise e
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
      flash[:success] = { key: "enable_location.success", replace: {name: location.name.upcase}}
      redirect_to list_locations_path('inactive')
    rescue Exception => e
      p e.message
      p e.class
      raise e
    end
  end
end