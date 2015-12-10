class PlayersController < ApplicationController
  layout 'cage'
  rescue_from PlayerProfile::PlayerNotFound, :with => :handle_player_not_found
  rescue_from PlayerProfile::PlayerNotActivated, :with => :handle_player_not_activated
  
  def balance
    player_info
  end

  def profile
    player_info
  end

  def player_info
    return unless permission_granted? :Player
    @operation = params[:action]
    member_id = params[:member_id]
    @player = policy_scope(Player).find_by_member_id(member_id)
    unless @player
      raise PlayerProfile::PlayerNotFound
    end
    balance_response = wallet_requester.get_player_balance(member_id, 'HKD', @player.id, @player.currency_id)
    @player_balance = balance_response[:balance]
    @credit_balance = balance_response[:credit_balance]
    @credit_expired_at = balance_response[:credit_expired_at]

    flash[:error] = "balance_enquiry.query_balance_fail" if @player_balance == 'no_balance' && flash[:alert].nil?

    respond_to do |format|
      format.html { render "players/player_info", formats: [:html] }
      format.js { render"players/player_info", formats: [:js] }
    end
  end

  def handle_player_not_activated(e)
    @player_balance = 'no_balance'
    @credit_balance = 'no_balance'
    @inactivate = true
    @player = e.player
    @operation = params[:operation]

    respond_to do |format|
      format.html { render "players/player_info", formats: [:html] }
      format.js { render"players/player_info", formats: [:js] }
    end
  end

  def search
    @operation = params[:operation]
    action = (@operation+ "?").to_sym unless @operation.nil?
    return unless permission_granted? :Player, action
    @id_number = params[:id_number]
    @id_type = params[:id_type]
    @player = Player.new

    respond_to do |format|
      format.html { render "players/search", formats: [:html] }
      format.js { render"players/search", formats: [:js] }
    end
  end

  def do_search
    @id_number = params[:id_number]
    @id_type = params[:id_type]
    @operation = params[:operation]
    
    begin
      requester_helper.update_player!(@id_type,@id_number)
    rescue Remote::PlayerNotFound => e
      Rails.logger.error 'PlayerNotFound in PIS'
    end

    @player = policy_scope(Player).find_by_id_type_and_number(@id_type, @id_number)
    raise PlayerProfile::PlayerNotFound unless @player
    member_id = @player.member_id
    redirect_to :action => @operation, :member_id => member_id
  end

  def handle_player_not_found(e)
    @show_not_found_message = true
    search
  end

  def lock_account
    return unless permission_granted? :Player, :lock?

    member_id = params[:member_id]
    player = policy_scope(Player).find_by_member_id(member_id)

    AuditLog.player_log("lock", current_user.name, client_ip, sid, :description => {:location => get_location_info, :shift => current_shift.name}) do
      player.lock_account!
    end

    ChangeHistory.create(current_user, player, 'lock')
    flash[:success] = { key: "lock_player.success", replace: {name: player.member_id}}
    redirect_to :action => 'profile', :member_id => member_id
  end

  def unlock_account
    return unless permission_granted? :Player, :unlock?

    member_id = params[:member_id]
    player = policy_scope(Player).find_by_member_id(member_id)

    AuditLog.player_log("unlock", current_user.name, client_ip, sid, :description => {:location => get_location_info, :shift => current_shift.name}) do
      player.unlock_account!
    end

    ChangeHistory.create(current_user, player, 'unlock')
    flash[:success] = { key: "unlock_player.success", replace: {name: player.member_id}}
    redirect_to :action => 'profile', :member_id => member_id
  end

  def create_pin
    @action = 'create_pin'
    @inactivate = true
    @player = Player.new(:member_id => params[:member_id], :card_id => params[:card_id], :status => 'not_activated')
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
    @operation = params[:operation]
    
    respond_to do |format|
      format.html { render "players/set_pin", formats: [:html] }
      format.js { render "players/set_pin", formats: [:js] }
    end
  end

  def do_reset_pin
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
      redirect_to :action => params[:operation], :member_id => params[:player][:member_id]
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
    @player = policy_scope(Player).find_by_member_id(member_id)
    @player = Player.new(:member_id => member_id, :card_id => card_id, :status => status) unless @player 
    @inactivate = inactivate
    @operation = operation
    respond_to do |format|
      format.html { render "players/set_pin", formats: [:html] }
      format.js { render"players/set_pin", formats: [:js] }
    end
  end
end
