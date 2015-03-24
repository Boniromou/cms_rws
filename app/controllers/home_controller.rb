class HomeController < ApplicationController
  def index
    respond_to do |format|
      format.html { render file: "home/index", :layout => "cage", formats: [:html] }
      format.js { render template: "home/index", formats: [:js] }
    end
  end
end
