class PlayersController < ApplicationController
  layout 'cage'
  before_filter :authorize_action, :only => [:balance, :profile, :lock, :unlock, :create_pin, :reset_pin, :do_reset_pin, :merge]
  before_filter :only => [:search, :do_search] do |controller|
    authorize_action :player, "#{params[:operation]}?".to_sym
  end
  rescue_from PlayerProfile::PlayerNotFound, :with => :handle_player_not_found
  rescue_from PlayerProfile::PlayerNotActivated, :with => :handle_player_not_activated
  rescue_from PlayerProfile::PlayerNotValidated, :with => :handle_player_not_validated
  def balance
    player_info
  end

  def profile
    player_info
  end

  def player_info
    clear_authorize_info
    @start_time = params[:start_time]
    @end_time = params[:end_time]
    @transaction_id = params[:transaction_id]
    @operation = params[:action]
    member_id = params[:member_id]
    @player = policy_scope(Player).find_by_member_id(member_id)

    @players = policy_scope(Player).where(member_id: member_id)

    @current_user = current_user
    @casino_id = params[:select_casino_id] || current_casino_id
    @member_id = params[:member_id]
    @exception_transaction = params[:exception_transaction]

    unless @player
      raise PlayerProfile::PlayerNotFound
    end
    balance_response = wallet_requester.get_player_balance(member_id, @player.currency.name, @player.id, @player.currency_id, @player.test_mode_player)
    @player_balance = balance_response.balance
    @credit_balance = balance_response.credit_balance
    @credit_expired_at = balance_response.credit_expired_at

    flash[:error] = "balance_enquiry.query_balance_fail" if @player_balance == 'no_balance' && flash[:fail].nil?

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
    @casino_id = params[:select_casino_id] || current_casino_id

    respond_to do |format|
      format.html { render "players/player_info", formats: [:html] }
      format.js { render"players/player_info", formats: [:js] }
    end
  end

  def search
    clear_authorize_info
    @operation = params[:operation]
    @id_number = params[:id_number]
    @id_type = params[:id_type]
    @player = Player.new
    @exception_transaction = params[:exception_transaction]

    respond_to do |format|
      format.html { render "players/search", formats: [:html] }
      format.js { render"players/search", formats: [:js] }
    end
  end

  def search_merge
    @operation = params[:operation]
    @id_number = params[:id_number]
    @id_type = params[:id_type]
    @player = Player.new

    respond_to do |format|
      format.html { render "players/search_merge", formats: [:html] }
      format.js { render"players/search_merge", formats: [:js] }
    end
  end

  def do_search
    @id_number = params[:id_number]
    @id_type = params[:id_type]
    @operation = params[:operation]
    @exception_transaction = params[:exception_transaction]

    begin
      requester_helper.update_player!(@id_type,@id_number)
    rescue Remote::PlayerNotFound => e
      Rails.logger.error 'PlayerNotFound in PIS'
    rescue PlayerProfile::PlayerNotValidated => e
      Rails.logger.error 'PlayerNotValidated'
      raise PlayerProfile::PlayerNotValidated
    end

    @player = policy_scope(Player).find_by_id_type_and_number(@id_type, @id_number)
    raise PlayerProfile::PlayerNotFound unless @player

    member_id = @player.member_id
    redirect_to :action => @operation, :member_id => member_id, :exception_transaction => @exception_transaction
  end

  def do_search_merge
    @card_id = params[:id_number]
    @card_id2 = params[:id_number2]
    @id_type = 'member_id'
    @operation = params[:operation]
    
    card_ids = [@card_id, @card_id2]

    @player = policy_scope(Player).find_by_id_type_and_number(@id_type, @card_id)
    @player2 = policy_scope(Player).find_by_id_type_and_number(@id_type, @card_id2)
    raise PlayerProfile::PlayerNotFound unless (@player && @player2 && (@player != @player2))
    
    @players = policy_scope(Player).where(member_id: [@card_id, @card_id2])
    @players = @players.index_by(&:member_id).values_at(*card_ids)

    @current_user = current_user
    @casino_id = params[:select_casino_id] || current_casino_id

    balance_response = wallet_requester.get_player_balance(@card_id, @player.currency.name, @player.id, @player.currency_id, @player.test_mode_player)
    @player_balance = balance_response.balance
    @credit_balance = balance_response.credit_balance
    @credit_expired_at = balance_response.credit_expired_at

    balance_response = wallet_requester.get_player_balance(@card_id2, @player2.currency.name, @player2.id, @player2.currency_id, @player2.test_mode_player)
    @player_balance2 = balance_response.balance
    @credit_balance2 = balance_response.credit_balance
    @credit_expired_at2 = balance_response.credit_expired_at

    flash[:error] = "balance_enquiry.query_balance_fail" if @player_balance == 'no_balance' && @player_balance2 == 'no_balance' && flash[:fail].nil?
  end

  def handle_player_not_found(e)
    flash[:error] = 'search_error.not_found'
    if @exception_transaction == nil
      search_merge
    else
      search
    end
  end

  def handle_player_not_validated(e)
    flash[:error] = 'search_error.not_validated'
    if @exception_transaction == nil
      search_merge
    else
      search
    end
  end

  def lock
    member_id = params[:member_id]
    player = policy_scope(Player).find_by_member_id(member_id)
    authorize_action player, :non_test_mode?

    lock_status = ''
    AuditLog.player_log("lock", current_user.name, client_ip, sid, :description => {:location => get_location_info, :shift => current_shift.name}) do
      if player.cage_locked?
        flash[:fail] = { key: "lock_player.fail", replace: {name: player.member_id}}
      else
        player.lock_account!
        lock_status = 'success'
        flash[:success] = { key: "lock_player.success", replace: {name: player.member_id}}
        ChangeHistory.create(current_user, player, 'lock')
      end
    end

    redirect_to :action => 'profile', :member_id => member_id
  end

  def unlock
    member_id = params[:member_id]
    player = policy_scope(Player).find_by_member_id(member_id)
    authorize_action player, :non_test_mode?

    lock_status = ''
    AuditLog.player_log("unlock", current_user.name, client_ip, sid, :description => {:location => get_location_info, :shift => current_shift.name}) do
      if !player.cage_locked?
        flash[:fail] = { key: "unlock_player.fail", replace: {name: player.member_id}}
      else
        player.unlock_account!
        flash[:success] = { key: "unlock_player.success", replace: {name: player.member_id}}
        ChangeHistory.create(current_user, player, 'unlock')
      end
    end

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
    @player = policy_scope(Player).find_by_member_id(member_id)
    set_pin
  end

  def set_pin
    @operation = params[:operation]
    authorize_action @player, :non_test_mode?

    respond_to do |format|
      format.html { render "players/set_pin", formats: [:html] }
      format.js { render "players/set_pin", formats: [:js] }
    end
  end

  def do_reset_pin
    member_id = params[:player][:member_id]
    player = policy_scope(Player).find_by_member_id(member_id)
    authorize_action player, :non_test_mode? if player
    begin
     audit_log = {:user => current_user.name, :member_id => params[:player][:member_id], :action_at => Time.now.utc, :action => params[:action].split('_')[0], :casino_id => current_casino_id}
      response = patron_requester.reset_pin(params[:player][:member_id], params[:pin], audit_log)
      unless response.success?
        flash[:error] = "reset_pin.call_patron_fail"
        Rails.logger.error "reset pin fail"
        redirect_to_set_pin_path(params[:player][:member_id], params[:player][:card_id], params[:status], params[:inactivate], params[:operation])
        return
      end
      player_info = response.player
      Player.update_info(player_info)
      flash[:success] = { key: "reset_pin.set_pin_success", replace: {name: params[:player][:member_id]}}
      redirect_to :action => params[:operation], :member_id => params[:player][:member_id]
    rescue Remote::PlayerNotFound
      flash[:error] = "reset_pin.set_pin_fail"
      redirect_to_set_pin_path(params[:player][:member_id], params[:player][:card_id], params[:status], params[:inactivate], params[:operation])
    end
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
