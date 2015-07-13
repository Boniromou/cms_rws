class LocationsController < ApplicationController
layout 'cage'
  include FormattedTimeHelper

  def show
   @locations = Location.all
    puts "dsfsasdfsfd"
    puts "dsfsasdfsfd"
    puts "dsfsasdfsfd"
    puts "dsfsasdfsfd"
    puts "dsfsasdfsfd"
    # @locations = Location.all
    
  end

  def new
    PlayerTransaction.new
    @name = params[:name]
  end

  def create
    Player.new
    begin
      AuditLog.loaction_log("create", current_user.employee_id, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        Player.transaction do
          Player.create_by_params(params[:player])
          # iwms_requester.create_player(params[:player][:member_id], 'HKD')
        end
      end 
    end
    
    puts "2121"
    puts "2121"
    puts "2121"
    puts "2121"
    puts "2121"
    puts "2121"
    puts "2121"
    puts params[:name]
    
    @loaction.name = params[:name]
    @loaction.save
    redirect_to show_locations_path
  end

  def disable
  	location_id = params[:location_id]
  	@location = Location.find(location_id)
  	@location.disable
  	redirect_to show_locations_path
  end

  def enable
  	location_id = params[:location_id]
  	@location = Location.find(location_id)
  	@location.enable
  	redirect_to show_locations_path
  end
end
