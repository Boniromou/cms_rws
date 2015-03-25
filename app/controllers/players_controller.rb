class PlayersController < ApplicationController
  def new
    @player = Player.new
    respond_to do |format|
      format.html {render file: "players/new", :layout => "cage", formats: [:html]}
      format.js { render template: "players/new", formats: [:js] }
    end
  end

  def create
    begin
      is_success = Player.create_by_param(params[:player][:member_id],params[:player][:player_name])
      if is_success
        redirect_to(home_index_path)
      else
        raise Exception.new
      end
    rescue Exception => e
      @player = Player.new(params[:player])
    flash[:alert] = e.message
      respond_to do |format|
        format.html {render file: "players/new", :layout => "cage", formats: [:html]}
      end
    end
  end

  def show
    @player = Player.find_by_id(1)
    @currency = Currency.find_by_id(@player.currency_id)
    respond_to do |format|
      format.html {render file: "players/show", :layout => "cage", formats: [:html]}
      format.js { render template: "players/show", formats: [:js] }
    end
    
  end
end
