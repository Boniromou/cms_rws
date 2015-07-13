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
  end
end
