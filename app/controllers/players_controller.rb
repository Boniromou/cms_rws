class PlayersController < ApplicationController
  layout 'cage'
  rescue_from PlayerProfile::PlayerNotFound, :with => :handle_player_not_found
  rescue_from PlayerProfile::PlayerNotActivated, :with => :handle_player_not_activated

  def new
    return unless permission_granted? :Player
    @player = Player.new
    @player.card_id = params[:card_id]
    @player.member_id = params[:member_id]
    @player.first_name = params[:first_name]
    @player.last_name = params[:last_name]
  end

  def create
    return unless permission_granted? :Player
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
    @operation = 'balance'
    player_info
  end

  def profile
    @operation = 'profile'
    player_info
  end

  def handle_player_not_activated(e)
    @player_balance = 'no_balance'
    @inactivate = true
    @player = e.player
    @operation = params[:operation]

    respond_to do |format|
      format.html { render "players/player_info", formats: [:html] }
      format.js { render"players/player_info", formats: [:js] }
    end
  end

  def player_info
    return unless permission_granted? :Player
    member_id = params[:member_id]
    @player = Player.find_by_member_id(member_id)
    unless @player
      raise PlayerProfile::PlayerNotFound
      @id_number = member_id
      @id_type = :member_id
    end
    @player_balance = wallet_requester.get_player_balance(member_id, 'HKD', @player.id, @player.currency_id)

    respond_to do |format|
      format.html { render "players/player_info", formats: [:html] }
      format.js { render"players/player_info", formats: [:js] }
    end
  end

  def search
    @operation = params[:operation] if params[:operation]
    action = (@operation+ "?").to_sym unless @operation.nil?
    return unless permission_granted? :Player, action
    @id_number = params[:id_number] if params[:id_number]
    @id_type = params[:id_type] if params[:id_type]
    @player = Player.new
    @search_title = "tree_panel." + @operation
    @found = params[:found]
  end

  def do_search
    @id_number = params[:id_number]
    @id_type = params[:id_type]
    @operation = params[:operation] if params[:operation]
    
    begin
      PlayerInfo.update!(@id_type,@id_number)
    rescue Remote::PlayerNotFound => e
      Rails.logger.error 'PlayerNotFound in PIS'
    end

    @player = Player.find_by_type_id(@id_type, @id_number)
    raise PlayerProfile::PlayerNotFound unless @player
    member_id = @player.member_id if @player
    redirect_to eval( @operation + "_path" )  + "?member_id=" + member_id
  end

  def handle_player_not_found(e)
    redirect_to :action => 'search', :found => false, :id_number => @id_number, :id_type => @id_type, :operation => @operation
  end

  def update
    return unless permission_granted? :Player
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
    return unless permission_granted? :Player, :lock?

    member_id = params[:member_id]
    player = Player.find_by_member_id(member_id)

    AuditLog.player_log("lock", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
      player.lock_account!
    end

    ChangeHistory.create(current_user, player, 'lock')
    flash[:success] = { key: "lock_player.success", replace: {name: player.full_name.upcase}}
    redirect_to :action => 'profile', :member_id => member_id
  end

  def unlock_account
    return unless permission_granted? :Player, :unlock?

    member_id = params[:member_id]
    player = Player.find_by_member_id(member_id)

    AuditLog.player_log("unlock", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
      player.unlock_account!
    end

    ChangeHistory.create(current_user, player, 'unlock')
    flash[:success] = { key: "unlock_player.success", replace: {name: player.full_name.upcase}}
    redirect_to :action => 'profile', :member_id => member_id
  end

  def create_pin
    @action = 'create_pin'
    @inactivate = true
    @player = Player.new(:member_id => params[:member_id], :card_id => params[:card_id], :status => 'not_activated')
    @operation = params[:operation]
    set_pin
  end

  def reset_pin
    @action = 'reset_pin'
    @inactivate = false
    member_id = params[:member_id]
    @player = Player.find_by_member_id(member_id)
    set_pin
  end

  def set_pin
    return unless permission_granted? :Player, :reset_pin?
    
    respond_to do |format|
      format.html { render "players/set_pin", formats: [:html] }
      format.js { render "players/set_pin", formats: [:js] }
    end
  end

  def do_reset_pin
    # TODO permission
    return unless permission_granted? :Player, :reset_pin?
    begin
      audit_log = {:user => current_user.name, :member_id => params[:player][:member_id], :action_at => Time.now.utc, :action => params[:action].split('_')[0]}
      player_info = patron_requester.reset_pin(params[:player][:member_id], params[:pin], audit_log)
      if player_info.class != Hash
        flash[:error] = "reset_pin.call_patron_fail"
        Rails.logger.error "reset pin fail"
        redirect_to_set_pin_path(params[:player][:member_id], params[:player][:card_id], params[:status], params[:inactivate], params[:operation])
        return
      end
      Player.update_info(player_info)
      flash[:success] = { key: "reset_pin.set_pin_success", replace: {name: params[:player][:member_id]}}
      redirect_to :action => 'profile', :member_id => params[:player][:member_id]
    rescue Remote::PlayerNotFound
      flash[:error] = "reset_pin.set_pin_fail"
      redirect_to_set_pin_path(params[:player][:member_id], params[:player][:card_id], params[:status], params[:inactivate], params[:operation])
    end
  end

  def player_not_activated
    player = Player.new(:member_id => params[:member_id], :card_id => params[:card_id], :status => params[:status])
    raise PlayerProfile::PlayerNotActivated.new(player)
  end

  protected
  def redirect_to_set_pin_path(member_id, card_id, status, inactivate, operation)
    @player = Player.find_by_member_id(member_id)
    @player = Player.new(:member_id => member_id, :card_id => card_id, :status => status) unless @player 
    @inactivate = inactivate
    @operation = operation
    respond_to do |format|
      format.html { render "players/set_pin", formats: [:html] }
      format.js { render"players/set_pin", formats: [:js] }
    end
  end
end
