class PlayersController < ApplicationController
  layout 'cage'
  def new
    return unless permission_granted? Player.new
    @player = Player.new
    @player.member_id = params[:member_id]
    @player.player_name = params[:player_name]
    @player.card_id = params[:card_id]
  end

  def create
    return unless permission_granted? Player.new
    begin
      is_success = false
      AuditLog.player_log("create", current_user.employee_id, client_ip, sid,:description => {:station => current_station, :shift => current_shift.name}) do
        is_success,@player = Player.create_by_param(params[:player][:member_id],params[:player][:player_name],params[:player][:card_id])
      end
      if is_success
        flash[:success] = "create_player.success"
        redirect_to :action => 'balance', :member_id => params[:player][:member_id]
      else
        raise Exception.new "Unkonwn error"
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :action => 'new', :member_id => params[:player][:member_id], :player_name => params[:player][:player_name], :card_id => params[:player][:card_id]
    end
  end

  def balance
    return unless permission_granted? Player.new
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
    return unless permission_granted? Player.new, action
    @id_number = params[:id_number] if params[:id_number]
    @id_type = params[:id_type] if params[:id_type]
    p "earch~~~~~~~~~~~~~~~~",params
    @player = Player.new
    @search_title = "tree_panel." + @operation
    @found = params[:found]
  end

  def do_search
    id_number = params[:id_number]
    id_type = params[:id_type]
    @operation = params[:operation] if params[:operation]
    @player = Player.find_by_type_id(id_type, id_number)
    member_id = @player.member_id if @player
    if @player.nil?
      redirect_to :action => 'search', :found => false, :id_number => id_number, :id_type => id_type, :operation => @operation
    else
      redirect_to eval( @operation + "_path" )  + "?member_id=" + member_id
    end
  end
end
