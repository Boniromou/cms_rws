class PlayersController < ApplicationController
  def new
    @player = Player.new
    flash[:alert] = "fail"
    respond_to do |format|
      format.html {render file: "players/new", :layout => "cage", formats: [:html]}
      format.js { render template: "players/new", formats: [:js] }
    end
  end

  def create
    begin
      is_success = Player.create_by_param(params[:player][:member_id],params[:player][:member_id])
      if is_success
        redirect_to(home_index_path)
      else
        raise Exception.new
      end
    rescue Exception => e
      @player = Player.new(params[:player])
      respond_to do |format|
        format.html {render file: "players/new", :layout => "cage", formats: [:html]}
      end
    end
  end
end
