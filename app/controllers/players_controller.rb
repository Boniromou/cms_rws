class PlayersController < ApplicationController
  def new
    @player = Player.new
    @player.member_id = params[:member_id]
    respond_to do |format|
      format.html {render file: "players/new", :layout => "cage", formats: [:html]}
      format.js { render template: "players/new", formats: [:js] }
    end
  end

  def create
    begin
      is_success = Player.create_by_param(params[:player][:member_id],params[:player][:player_name])
      if is_success
        flash[:success] = "create_player.success"
        redirect_to :action => 'balance', :member_id => params[:player][:member_id]
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

  def balance
    begin
      member_id = params[:member_id]
      @player = Player.find_by_member_id(member_id)
      @currency = Currency.find_by_id(@player.currency_id)
      respond_to do |format|
        format.html {render file: "players/show", :layout => "cage", formats: [:html]}
        format.js { render template: "players/show", formats: [:js] }
      end
    rescue Exception => e
      flash[:alert] = "player not found"
      redirect_to(new_player_path+"?member_id=#{member_id}")
    end
  end

  def search
    @player = Player.new
    @player.member_id = params[:member_id]
    operation = "balance"
    operation = params[:operation] if params[:operation]
    @search_title = "tree_panel." + operation
    @found = params[:found]
    respond_to do |format|
      format.html {render file: "players/search", :layout => "cage", formats: [:html]}
      format.js { render template: "players/search", formats: [:js] }
    end
  end

  def do_search
    member_id = params[:player][:member_id]
    operation = "balance"
    operation = params[:operation] if params[:operation]
    @player = Player.find_by_member_id(member_id)
    if @player.nil?
      redirect_to :action => 'search', :found => false, :member_id => member_id
    else
      redirect_to :action => operation, :member_id => member_id
    end
  end
end
