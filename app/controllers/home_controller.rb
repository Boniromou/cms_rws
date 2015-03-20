class HomeController < ApplicationController
  def index
    respond_to do |format|
      format.html { render file: "home/index", :layout => "cage", formats: [:html] }
    end
  end
end
