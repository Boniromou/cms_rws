class PlayersController < ApplicationController
  layout 'cage'

  def new
    return unless permission_granted? Player.new
    @player = Player.new
    @player.card_id = params[:card_id]
    @player.member_id = params[:member_id]
    @player.first_name = params[:first_name]
    @player.last_name = params[:last_name]
  end

  def create
    return unless permission_granted? Player.new
    begin
      AuditLog.player_log("create", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        player = Player.create_by_params(params[:player])
        wallet_requester.create_player(params[:player][:member_id], 'HKD', player.id, player.currency_id)
      end
      flash[:success] = {key: "create_player.success", replace: {first_name: params[:player][:first_name].upcase, last_name: params[:player][:last_name].upcase}}
      redirect_to :action => 'balance', :member_id => params[:player][:member_id]
    rescue CreatePlayer::ParamsError => e
      flash[:error] = "create_player." + e.message
      redirect_to :action => 'new', :card_id => params[:player][:card_id], :member_id => params[:player][:member_id], :first_name => params[:player][:first_name], :last_name => params[:player][:last_name]
    rescue CreatePlayer::DuplicatedFieldError => e
      field = e.message
      flash[:error] = {key: "create_player." + field + "_exist", replace: {field.to_sym => params[:player][field.to_sym]}}
      redirect_to :action => 'new', :card_id => params[:player][:card_id], :member_id => params[:player][:member_id], :first_name => params[:player][:first_name], :last_name => params[:player][:last_name]
    end
  end

  def balance
    return unless permission_granted? Player.new
    begin
      member_id = params[:member_id]
      @player = Player.find_by_member_id(member_id)
      @currency = Currency.find_by_id(@player.currency_id)
      @player_balance = wallet_requester.get_player_balance(member_id)
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

  def profile
    begin
      member_id = params[:member_id]
      @player = Player.find_by_member_id(member_id)
      @player_balance = wallet_requester.get_player_balance(member_id)
    rescue Exception => e
      flash[:alert] = "player not found"
      redirect_to(players_search_path+"?member_id=#{member_id}&operation=balance")
    end
  end

  def edit
    member_id = params[:member_id]
    @player = Player.find_by_member_id(member_id)
  end

  def update
    return unless permission_granted? Player.new
    begin
      AuditLog.player_log("edit", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        Player.update_by_params(params[:player])
      end
      flash[:success] = {key: "update_player.success", replace: {first_name: params[:player][:first_name].upcase, last_name: params[:player][:last_name].upcase}}
      redirect_to :action => 'profile', :member_id => params[:player][:member_id]
    rescue RuntimeError => e
      flash[:error] = "update_player." + e.message
      redirect_to :action => 'edit', :card_id => params[:player][:card_id], :member_id => params[:player][:member_id], :first_name => params[:player][:first_name], :last_name => params[:player][:last_name]
    end
  end

  def lock_account
    return unless permission_granted? Player.new, :lock?

    begin
      member_id = params[:member_id]
      player = Player.find_by_member_id(member_id)

      AuditLog.player_log("lock", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        player.lock_account!
      end

      flash[:success] = { key: "lock_player.success", replace: {first_name: player.first_name.upcase, last_name: player.last_name.upcase}}
      redirect_to :action => 'profile', :member_id => member_id
    rescue Exception => e
      p e.message
      p e.class
      raise e
    end
  end

  def unlock_account
    return unless permission_granted? Player.new, :unlock?

    begin
      member_id = params[:member_id]
      player = Player.find_by_member_id(member_id)

      AuditLog.player_log("unlock", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        player.unlock_account!
      end

      flash[:success] = { key: "unlock_player.success", replace: {first_name: player.first_name.upcase, last_name: player.last_name.upcase}}
      redirect_to :action => 'profile', :member_id => member_id
    rescue Exception => e
      p e.message
      p e.class
      raise e
    end
  end
end
