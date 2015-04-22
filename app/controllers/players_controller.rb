class PlayersController < ApplicationController
  layout 'cage'
  def new
    return unless check_permission Player.new
    @player = Player.new
    @player.member_id = params[:member_id]
    @player.player_name = params[:player_name]
  end

  def create
    return unless check_permission Player.new
    begin
      is_success = false
      AuditLog.player_log("create", current_user.employee_id, client_ip, sid,:description => {:station => current_station, :shift => current_shift.shift_type}) do
        is_success,@player = Player.create_by_param(params[:player][:member_id],params[:player][:player_name])
      end
      if is_success
        flash[:success] = "create_player.success"
        redirect_to :action => 'balance', :member_id => params[:player][:member_id]
      else
        raise Exception.new "Unkonwn error"
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :action => 'new', :member_id => params[:player][:member_id], :player_name => params[:player][:player_name]
    end
  end

  def balance
    return unless check_permission Player.new
    begin
      member_id = params[:member_id]
      @player = Player.find_by_member_id(member_id)
      @currency = Currency.find_by_id(@player.currency_id)
    rescue Exception => e
      flash[:alert] = "player not found"
      redirect_to(players_search_path+"?member_id=#{member_id}&operation=balance")
    end
  end

  def search
    @operation = params[:operation] if params[:operation]
    action = (@operation+ "?").to_sym unless @operation.nil?
    return unless check_permission Player.new, action
    @player = Player.new
    @player.member_id = params[:member_id]
    @search_title = "tree_panel." + @operation
    @found = params[:found]
  end

  def do_search
    member_id = params[:player][:member_id]
    @operation = params[:operation] if params[:operation]
    @player = Player.find_by_member_id(member_id)
    if @player.nil?
      redirect_to :action => 'search', :found => false, :member_id => member_id, :operation => @operation
    else
      redirect_to eval( @operation + "_path" ) + "?member_id=" + member_id
    end
  end
end
