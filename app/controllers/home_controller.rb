class HomeController < ApplicationController
  def index
    set_location_info
    @time_zone = current_user.time_zone

    respond_to do |format|
      format.html { render file: "home/index", :layout => "cage", formats: [:html] }
      format.js { render template: "home/index", formats: [:js] }
    end
  end
end
