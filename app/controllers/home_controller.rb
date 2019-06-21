class HomeController < ApplicationController
  def index
    set_location_info
    @time_zone = current_licensee_time_zone
    p '1111111111111111111111111111111111111111'
    p @time_zone
    p '1111111111111111111111111111111111111111'

    respond_to do |format|
      format.html { render file: "home/index", :layout => "cage", formats: [:html] }
      format.js { render template: "home/index", formats: [:js] }
    end
  end
end
