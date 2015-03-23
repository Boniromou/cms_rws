class PlayersController < ApplicationController
  def new
    @player = Player.new
    respond_to do |format|
      format.html {render file: "players/new", :layout => "cage", formats: [:html]}
    end
  end
end
