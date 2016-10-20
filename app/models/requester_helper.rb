class RequesterHelper

  def initialize(requester_factory)
    @requester_factory = requester_factory
  end
  
  def patron_requester
    @requester_factory.get_patron_requester
  end

  def wallet_requester
    @requester_factory.get_wallet_requester
  end

  def station_requester
    @requester_factory.get_station_requester
  end

  def retrieve_info(card_id, machine_type, machine_token, pin, casino_id)
    begin
      property_id = Machine.parse_machine_token(machine_token)[:property_id]
      raise Request::InvalidMachineToken.new  unless validate_machine_token(machine_type ,machine_token, property_id, casino_id)
      player = Player.find_by_card_id_and_casino_id(card_id, casino_id)
      raise Request::InvalidCardId.new unless player
      raise Request::PlayerLocked.new if player.account_locked?
      login_name = player.member_id
      raise Request::InvalidPin.new unless validate_pin(login_name, pin)
      currency = player.currency.name
      balance_response = wallet_requester.get_player_balance(player.member_id)
      balance = balance_response.balance
      credit_balance = balance_response.credit_balance
      credit_expired_at = balance_response.credit_expired_at
      raise Request::RetrieveBalanceFail.new unless balance.class == Float
      session_token = Token.generate(player.id, casino_id).session_token
      {:login_name => login_name, :currency => currency, :balance => balance, :credit_balance => credit_balance, :credit_expired_at => credit_expired_at, :session_token => session_token, :test_mode_player => player.test_mode_player}
    end
  end

  def validate_machine_token(machine_type, machine_token, property_id, casino_id)
    response = validate_machine(machine_type, machine_token, property_id, casino_id)
    return true if response.success?
    false
  end

  def validate_machine(machine_type, machine_token, property_id, casino_id)
    response = station_requester.validate_machine_token(machine_type, machine_token, property_id, casino_id)
  end


  def validate_pin(login_name, pin)
    begin
      response = patron_requester.validate_pin(login_name, pin)
      if response.success?
        return true
      else
        return false
      end
    rescue Remote::PinError
    rescue Remote::PlayerNotFound
      return false
    end
  end
  
  def update_player!(id_type, id_value)
    response = patron_requester.get_player_info(id_type, id_value)
    unless response.success?
      Rails.logger.error "update player info fail"
      return
    end
    player_info = response.player
    if player_info && player_info[:pin_status] == 'blank'
      player = Player.create_inactivate(player_info)
      raise PlayerProfile::PlayerNotActivated.new(player)
    end
    Player.update_info(player_info)
  end

  def update_player(id_type, id_value)
    begin
      update_player!(id_type, id_value)
    rescue PlayerProfile::PlayerNotActivated => e
      return 'PlayerNotActivated'
    end
  end

  def kiosk_login(card_id, pin, casino_id)
    player = Player.find_by_card_id_and_casino_id(card_id, casino_id)
    raise Request::InvalidCardId unless player
    raise Request::PlayerLocked if player.account_locked?
    login_name = player.member_id
    raise Request::InvalidPin unless validate_pin(login_name, pin)
    currency = player.currency.name
    balance_response = wallet_requester.get_player_balance(player.member_id)
    balance = balance_response.balance
    raise Request::RetrieveBalanceFail unless balance.class == Float
    session_token = Token.generate(player.id, casino_id).session_token
    {:login_name => login_name, :currency => currency, :balance => balance, :session_token => session_token}
  end

  def validate_deposit(login_name, ref_trans_id, amount, kiosk_id, session_token, source_type, casino_id)
    licensee_id = Casino.get_licensee_id_by_casino_id(casino_id)
    Token.validate(login_name, session_token, licensee_id)
    player = Player.find_by_member_id_and_casino_id(login_name, casino_id)
    balance_response = wallet_requester.get_player_balance(player.member_id)
    balance = balance_response.balance
    kiosk_transaction = KioskTransaction.find_by_ref_trans_id(ref_trans_id)
    raise Request::RetrieveBalanceFail unless balance.class == Float
    raise Request::InvalidAmount unless PlayerTransaction.is_amount_str_valid?(amount)
    server_amount = PlayerTransaction.to_server_amount(amount)
    if !kiosk_transaction.nil?
      raise Request::AlreadyProcessed if kiosk_transaction.player.member_id == login_name && kiosk_transaction.amount == server_amount
      raise Request::DuplicateTrans
    end
    raise Request::OutOfDailyLimit if player.out_of_daily_limit?(server_amount, :deposit, casino_id)
    kiosk_transaction = KioskTransaction.save_deposit_transaction(login_name, server_amount, Shift.current(casino_id).id, kiosk_id, ref_trans_id, source_type, casino_id)
    {:amt => amount, :trans_date => kiosk_transaction.trans_date.localtime.strftime("%Y-%m-%d %H:%M:%S"), :balance => balance}
  end

  def deposit(login_name, ref_trans_id, session_token, casino_id)
    licensee_id = Casino.get_licensee_id_by_casino_id(casino_id)
    Token.validate(login_name, session_token, licensee_id)
    kiosk_transaction = KioskTransaction.find_by_ref_trans_id(ref_trans_id)
    raise Request::AlreadyCancelled if !kiosk_transaction.nil? && kiosk_transaction.cancelled?
    raise Request::InvalidDeposit if kiosk_transaction.nil? || !kiosk_transaction.validated?
    submit_kiosk_transaction(kiosk_transaction, :deposit)
    {}
  end

  def submit_kiosk_transaction(kiosk_transaction, trans_type)
    kt = kiosk_transaction
    kt.pending! if kt.validated?
    begin
      response = wallet_requester.send trans_type,kt.player.member_id, PlayerTransaction.cents_to_dollar(kt.amount), kt.ref_trans_id, kt.created_at.localtime, kt.source_type
      raise Request::RetrieveBalanceFail unless response.success?
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.inspect
      raise Request::RetrieveBalanceFail
    end
    KioskTransaction.transaction do
      kt.trans_date = response.trans_date
      kt.completed!
    end
    response
  end

  def withdraw(login_name, ref_trans_id, amount, kiosk_id, session_token, source_type, casino_id)
    licensee_id = Casino.get_licensee_id_by_casino_id(casino_id)
    Token.validate(login_name, session_token, licensee_id)
    player = Player.find_by_member_id_and_casino_id(login_name, casino_id)
    raise Request::InvalidAmount unless PlayerTransaction.is_amount_str_valid?(amount)
    server_amount = PlayerTransaction.to_server_amount(amount)
    kiosk_transaction = KioskTransaction.find_by_ref_trans_id(ref_trans_id)
    if !kiosk_transaction.nil?
      raise Request::AlreadyProcessed if kiosk_transaction.player.member_id == login_name && kiosk_transaction.amount == server_amount
      raise Request::DuplicateTrans
    end
    raise Request::OutOfDailyLimit if player.out_of_daily_limit?(server_amount, :withdraw, casino_id)
    kiosk_transaction = KioskTransaction.save_withdraw_transaction(login_name, server_amount, Shift.current(casino_id).id, kiosk_id, ref_trans_id, source_type, casino_id)
    response = submit_kiosk_transaction(kiosk_transaction, :withdraw)
    {:amt => amount, :trans_date => kiosk_transaction.trans_date.localtime.strftime("%Y-%m-%d %H:%M:%S"), :balance => response.balance}
  end
end
