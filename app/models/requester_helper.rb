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

  def retrieve_info(card_id, machine_type, machine_token, pin, property_id)
    begin
      raise Request::InvalidMachineToken.new  unless validate_machine_token(machine_type ,machine_token, property_id)
      player = Player.find_by_card_id_and_property_id(card_id, property_id)
      raise Request::InvalidCardId.new unless player
      raise Request::PlayerLocked.new if player.account_locked?
      login_name = player.member_id
      raise Request::InvalidPin.new unless validate_pin(login_name, pin)
      currency = player.currency.name
      balance_response = wallet_requester.get_player_balance(player.member_id)
      balance = balance_response[:balance]
      credit_balance = balance_response[:credit_balance]
      credit_expired_at = balance_response[:credit_expired_at]
      raise Request::RetrieveBalanceFail.new unless balance.class == Float
      session_token = Token.generate(player.id).session_token
      {:login_name => login_name, :currency => currency, :balance => balance, :credit_balance => credit_balance, :credit_expired_at => credit_expired_at, :session_token => session_token}
    end
  end

  def validate_machine_token(machine_type, machine_token, property_id)
    response = validate_machine(machine_type, machine_token, property_id)
    return true if response[:error_code] == 'OK'
    false
  end

  def validate_machine(machine_type, machine_token, property_id)
    response = station_requester.validate_machine_token(machine_type, machine_token, property_id)
  end


  def validate_pin(login_name, pin)
    begin
      response = patron_requester.validate_pin(login_name, pin)
      unless response_valid?(response)
        Rails.logger.error "validate pin fail"
        raise Remote::CallPatronFail.new
      else
        return true
      end
    rescue Remote::PinError
    rescue Remote::PlayerNotFound
      return false
    end
  end
  
  def update_player!(id_type, id_value)
    player_info = patron_requester.get_player_info(id_type, id_value)
    unless response_valid?(player_info)
      Rails.logger.error "update player info fail"
      return
    end
    if player_info[:pin_status] == 'blank'
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

  private
  def response_valid?(response)
    response.class == Hash
  end
end
